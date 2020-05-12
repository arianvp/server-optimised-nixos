{ config, lib, pkgs, ... }:

# with utils;
with lib;
with import ./systemd-unit-options.nix { inherit config lib; };
with import ./systemd-lib.nix { inherit config lib pkgs; };

let

  cfg = config.systemd;

  systemd = cfg.package;

  commonUnitText = def: ''
    [Unit]
    ${attrsToSection def.unitConfig}
  '';

  targetToUnit = name: def:
    {
      inherit (def) aliases wantedBy requiredBy enable;
      text = commonUnitText def;
    };

  serviceToUnit = name: def:
    {
      inherit (def) aliases wantedBy requiredBy enable;
      text = commonUnitText def + ''
        [Service]
        ${let
        env = def.environment;
      in
        concatMapStrings (
          n:
            let
              s = optionalString (env.${n} != null)
                "Environment=${builtins.toJSON "${n}=${env.${n}}"}\n";
              # systemd max line length is now 1MiB
              # https://github.com/systemd/systemd/commit/e6dde451a51dc5aaa7f4d98d39b8fe735f73d2af
            in
              if stringLength s >= 1048576 then throw "The value of the environment variable ‘${n}’ in systemd service ‘${name}.service’ is too long." else s
        ) (attrNames env)}
        ${attrsToSection def.serviceConfig}
      '';
    };

  socketToUnit = name: def:
    {
      inherit (def) aliases wantedBy requiredBy enable;
      text = commonUnitText def + ''
        [Socket]
        ${attrsToSection def.socketConfig}
      '';
    };

  timerToUnit = name: def:
    {
      inherit (def) aliases wantedBy requiredBy enable;
      text = commonUnitText def + ''
        [Timer]
        ${attrsToSection def.timerConfig}
      '';
    };

  pathToUnit = name: def:
    {
      inherit (def) aliases wantedBy requiredBy enable;
      text = commonUnitText def + ''
        [Path]
        ${attrsToSection def.pathConfig}
      '';
    };

  mountToUnit = name: def:
    {
      inherit (def) aliases wantedBy requiredBy enable;
      text = commonUnitText def + ''
        [Mount]
        ${attrsToSection def.mountConfig}
      '';
    };

  automountToUnit = name: def:
    {
      inherit (def) aliases wantedBy requiredBy enable;
      text = commonUnitText def + ''
        [Automount]
        ${attrsToSection def.automountConfig}
      '';
    };

  sliceToUnit = name: def:
    {
      inherit (def) aliases wantedBy requiredBy enable;
      text = commonUnitText def + ''
        [Slice]
        ${attrsToSection def.sliceConfig}
      '';
    };

in

{
  imports = [ ./environment.nix ];
  options = {

    systemd.package = mkOption {
      default = pkgs.systemd;
      defaultText = "pkgs.systemd";
      type = types.package;
      description = "The systemd package.";
    };

    systemd.units = mkOption {
      description = "Definition of systemd units.";
      default = {};
      type = with types; attrsOf (
        submodule (
          { name, config, ... }:
            {
              options = concreteUnitOptions;
              config = {
                unit = mkDefault (makeUnit name config);
              };
            }
        )
      );
    };

    systemd.packages = mkOption {
      default = [];
      type = types.listOf types.package;
      example = literalExample "[ pkgs.systemd-cryptsetup-generator ]";
      description = "Packages providing systemd units";
    };

    systemd.targets = mkOption {
      default = {};
      type = with types; attrsOf (submodule [ { options = targetOptions; } ]);
      description = "Definition of systemd target units.";
    };

    systemd.services = mkOption {
      default = {};
      type = with types; attrsOf (submodule { options = serviceOptions; });
      description = "Definition of systemd service units.";
    };

    systemd.sockets = mkOption {
      default = {};
      type = with types; attrsOf (submodule [ { options = socketOptions; } ]);
      description = "Definition of systemd socket units.";
    };

    systemd.timers = mkOption {
      default = {};
      type = with types; attrsOf (submodule [ { options = timerOptions; } ]);
      description = "Definition of systemd timer units.";
    };

    systemd.paths = mkOption {
      default = {};
      type = with types; attrsOf (submodule [ { options = pathOptions; } ]);
      description = "Definition of systemd path units.";
    };

    systemd.mounts = mkOption {
      default = [];
      type = with types; listOf (submodule { options = mountOptions; });
      description = ''
        Definition of systemd mount units.
        This is a list instead of an attrSet, because systemd mandates the names to be derived from
        the 'where' attribute.
      '';
    };

    systemd.automounts = mkOption {
      default = [];
      type = with types; listOf (submodule { options = automountOptions; });
      description = ''
        Definition of systemd automount units.
        This is a list instead of an attrSet, because systemd mandates the names to be derived from
        the 'where' attribute.
      '';
    };

    systemd.slices = mkOption {
      default = {};
      type = with types; attrsOf (submodule [ { options = sliceOptions; } ]);
      description = "Definition of slice configurations.";
    };

    systemd.generators = mkOption {
      type = types.attrsOf types.path;
      default = {};
      example = { systemd-gpt-auto-generator = "/dev/null"; };
      description = ''
        Definition of systemd generators.
        For each <literal>NAME = VALUE</literal> pair of the attrSet, a link is generated from
        <literal>/etc/systemd/system-generators/NAME</literal> to <literal>VALUE</literal>.
      '';
    };

    systemd.tmpfiles.rules = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "d /tmp 1777 root root 10d" ];
      description = ''
        Rules for creating and cleaning up temporary files
        automatically. See
        <citerefentry><refentrytitle>tmpfiles.d</refentrytitle><manvolnum>5</manvolnum></citerefentry>
        for the exact format.
      '';
    };

  };


  ###### implementation

  config = {


    system.build.units = cfg.units;

    # Systemd provides various NSS modules to look up dynamic users, locally
    # configured IP adresses and local container hostnames.
    # On NixOS, these can only be passed to the NSS system via nscd (and its
    # LD_LIBRARY_PATH), which is why it's usually a very good idea to have nscd
    # enabled (also see the config.nscd.enable description).
    # While there is already an assertion in place complaining loudly about
    # having nssModules configured and nscd disabled, for some reason we still
    # check for nscd being enabled before adding to nssModules.
    # TODO: Implement nss
    # system.nssModules = optional config.services.nscd.enable systemd.out;
    # system.nssDatabases = mkIf config.services.nscd.enable {
    #   hosts = (mkMerge [
    #     [ "mymachines" ]
    #     (mkOrder 1600 [ "myhostname" ] # 1600 to ensure it's always the last
    #   )
    #   ]);
    #   passwd = (mkMerge [
    #     [ "mymachines" ]
    #     (mkAfter [ "systemd" ])
    #   ]);
    # };

    # TODO: environment.systemPackages
    # environment.systemPackages = [ systemd ];

    # Include all systemd packages for now TODO: In the future make smaller or
    # something? Idk. we probably want to remain as vanilla as possible so
    # maybe not make this configurable
    systemd.packages = [ systemd ];

    environment.etc = let
      enabledUnits = filterAttrs (n: v: ! elem n cfg.suppressedSystemUnits) cfg.units;
    in
      {
        "systemd/system".source = generateUnits "system" enabledUnits enabledUpstreamSystemUnits upstreamSystemWants;

        # "systemd/user".source = generateUnits "user" cfg.user.units upstreamUserUnits [];


        # TODO: tmpfiles?
        # "tmpfiles.d/home.conf".source = "${systemd}/example/tmpfiles.d/home.conf";
        # "tmpfiles.d/journal-nocow.conf".source = "${systemd}/example/tmpfiles.d/journal-nocow.conf";
        # "tmpfiles.d/portables.conf".source = "${systemd}/example/tmpfiles.d/portables.conf";
        # "tmpfiles.d/static-nodes-permissions.conf".source = "${systemd}/example/tmpfiles.d/static-nodes-permissions.conf";
        # "tmpfiles.d/systemd.conf".source = "${systemd}/example/tmpfiles.d/systemd.conf";
        # "tmpfiles.d/systemd-nologin.conf".source = "${systemd}/example/tmpfiles.d/systemd-nologin.conf";
        # "tmpfiles.d/systemd-nspawn.conf".source = "${systemd}/example/tmpfiles.d/systemd-nspawn.conf";
        # "tmpfiles.d/systemd-tmp.conf".source = "${systemd}/example/tmpfiles.d/systemd-tmp.conf";
        # "tmpfiles.d/tmp.conf".source = "${systemd}/example/tmpfiles.d/tmp.conf";
        # "tmpfiles.d/var.conf".source = "${systemd}/example/tmpfiles.d/var.conf";
        # "tmpfiles.d/x11.conf".source = "${systemd}/example/tmpfiles.d/x11.conf";

      };

    # TODO: Enable dbus
    # services.dbus.enable = true;

    # TODO: Ship sysusers.d file

    systemd.units =
      mapAttrs' (n: v: nameValuePair "${n}.path" (pathToUnit n v)) cfg.paths
      // mapAttrs' (n: v: nameValuePair "${n}.service" (serviceToUnit n v)) cfg.services
      // mapAttrs' (n: v: nameValuePair "${n}.slice" (sliceToUnit n v)) cfg.slices
      // mapAttrs' (n: v: nameValuePair "${n}.socket" (socketToUnit n v)) cfg.sockets
      // mapAttrs' (n: v: nameValuePair "${n}.target" (targetToUnit n v)) cfg.targets
      // mapAttrs' (n: v: nameValuePair "${n}.timer" (timerToUnit n v)) cfg.timers
      // listToAttrs (
        map
          (
            v: let
              n = escapeSystemdPath v.where;
            in
              nameValuePair "${n}.mount" (mountToUnit n v)
          ) cfg.mounts
      )
      // listToAttrs (
        map
          (
            v: let
              n = escapeSystemdPath v.where;
            in
              nameValuePair "${n}.automount" (automountToUnit n v)
          ) cfg.automounts
      );


    # Generate timer units for all services that have a ‘startAt’ value.
    systemd.timers =
      mapAttrs (
        name: service:
          {
            wantedBy = [ "timers.target" ];
            timerConfig.OnCalendar = service.startAt;
          }
      )
        (filterAttrs (name: service: service.enable && service.startAt != []) cfg.services);

    # Some overrides to upstream units.
    # TODO: activation logic. Only restart units that are After=sysinit.target :)
  };

}
