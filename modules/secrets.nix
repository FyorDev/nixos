# Secrets encrypted via ssh key
{ config, ... }:
{
  age = {
    identityPaths = [ "${config.users.users.${config.user.name}.home}/.ssh/id_ed25519" ];
    secrets.fmod = {
      file = ../secrets/fmod.env.age;
      owner = config.user.name;
      mode = "0400";
    };
    secrets.obs-websocket = {
      file = ../secrets/obs-websocket.age;
      owner = config.user.name;
      mode = "0400";
    };
  };
}
