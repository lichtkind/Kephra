use v5.16;
use warnings;

for my $proto_dir (<*>){
    next unless -d $proto_dir and $proto_dir ne '.' and $proto_dir ne '..';
    chdir $proto_dir;
    if (-d 't') { system 'prove' }
    else {
        for my $dir (<*>){
            next unless -d $dir and $dir ne '.' and $dir ne '..' and -d $dir.'/t';
            chdir $dir;
            system 'prove'; 
            chdir '..';
        }
    }
    chdir '..';
}
