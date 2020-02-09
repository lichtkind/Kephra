
__END__
$bmp->LoadFile( File::Spec->catfile( $path, $files[$filenr]), wxBITMAP_TYPE_PNG );
$bmp->SaveFile( $file, wxBITMAP_TYPE_XPM );
