{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
	vim    
	git
gawk
	    sbctl
	    os-prober
  ];
}
