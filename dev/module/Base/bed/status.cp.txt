
          ==[[ module prototype Kephra Base ]]==

This is the lowest level core of the packages that extend Perl.
See connections between stages and module protos under /dev/module/status.cp

--------------------------------------------------------------------------------
   K ~~ Kephra                            C = Complete
     B ~~ Base                            .P = Partially there, nothing missing now (or only tests)
       C ~~ Class                         . S = Small feature missing
                                          .  U = Usable
                                          .   M = Major feature missing
                                          .    B = Buggy/old Deprecated code
                                          .     I = In Progress (currently worked on)
                                          .      N = Not yet (planned)
--------------------------------------------------------------------------------
   K::B::Package  ......................  C  .....  1.1    low level symbol manipulation
   K::B::Data::Type::Basic  ............  C  .....  1.6    inheritable single value checker
   K::B::Data::Type::Parametric  .......  C  .....  1.5    checks relation between two values
   K::B::Data::Type::Store  ............  C  .....  1.21   collection of type objects (namespace)
   K::B::Data::Type::Util  .............  C  .....  1.01   helper functions for type creation
   K::B::Data::Type::Standard  .........  C  .....  2.8    definition of standard types
   K::B::Data::Type  ...................  C  .....  1.51   manage type related symbols
   K::B::Data  .........................  C  .....  0.2    root of none OO data handling
   K::B::Closure  ......................  C  .....  1.1    serializable closure (code and data)
   K::Base  ............................  C  .....  0.11   root package of self made language extensions
================================================================================
