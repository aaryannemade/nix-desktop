{ ... }:

{
  wayland.windowManager.mango = {
    enable = true;

    settings = {
        # Window effects
        blur = 0;
	blur_layer = 0;
	blur_optimized = 1;
	blur_params_radius = 5;
	blur_params_noise = 0.02;
	blur_params_brightness = 0.9;
	blur_params_contrast = 0.9;
	blur_params_saturation = 1.2;

        # Animations - use underscores for multi-part keys
        animations = 1;
        animation_type_open = "slide";
        animation_type_close = "slide";
        animation_duration_open = 400;
        animation_duration_close = 800;

        # Or use nested attrs (will be flattened with underscores)
        animation_curve = {
            open = "0.46,1.0,0.29,1";
            close = "0.08,0.92,0,1";
        };

        # Use lists for duplicate keys like bind and tagrule
        bind = [
            "Super,r,reload_config"
            # "Alt,space,spawn,rofi -show drun"
            "Alt,Return,spawn,ghostty"
            "Alt,q,killclient"
            "Super,m,quit"
        ];

        tagrule = [
            "id:1,layout_name:tile"
            "id:2,layout_name:scroller"
        ];

        # Keymodes (submaps) for modal keybindings
        keymode = {
            resize = {
            bind = [
                "NONE,Left,resizewin,-10,0"
                "NONE,Escape,setkeymode,default"
            ];
            };
        };
    };
  };
}
