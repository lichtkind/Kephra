use v5.12;

use Prima qw(Application Buttons MsgBox);


message('Hello world', mb::OkCancel|mb::Information,
        buttons => {
                mb::Cancel => {
                        # there are predefined color constants to use
                        backColor => cl::LightGreen,
                        # but RGB integers are also o.k.
                        color     => 0xFFFFFF,
                },
                mb::Ok => {
                        text    => 'Indeed',
                },
        }
);

run Prima;

