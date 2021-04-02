
          ==[[ module prototype Kephra Base Class ]]==

Kephra's own object system with class types, signature checking, real data hiding,
serialisation, interfaces and three types of attributes and 4 scopes. 
See connections between stages and module protos under /dev/module/status.cp

depends on:
  - Kephra::Base

--------------------------------------------------------------------------------
   K ~~ Kephra                            C = Complete
      B ~~ Base                           .P = Partially there, nothing missing now (or only tests)
        C ~~ Class                        . S = Small feature missing
                                          .  U = Usable
                                          .   M = Major feature missing
                                          .    B = Buggy/old Deprecated code
                                          .     I = In Progress (currently worked on)
                                          .      N = Not yet (planned)
--------------------------------------------------------------------------------
   K::B::C::Definition::Attr.::Data  ...  C  .....  1.23   validate and serialize definition of attribute holding raw data
   K::B::C::Definition::Attr.::Delegating C  .....  1.21   validate and serialize definition of attribute, which is KBOS object
   K::B::C::Definition::Attr.::Wrapping   C  .....  1.1    validate and serialize definition of attribute, which is a none KBOS object
   K::B::C::Definition::Attribute  .....  C  .....  1.0    validate and serialize attribute definition
   K::B::C::Definition::Method::Signature     M...  0.0    validate and serialize signature definition
   K::B::C::Definition::Method  ........        I.  0.0    validate and serialize method definition
   K::B::C::Definition  ................     UM...  0.7    serializable data set to build a KBOS class from
   K::B::C::Scope  .....................  C         1.5    namespace constants, paths & priority logic
   K::B::C::Instance::Attribute  .......       B N         central store for attribute values
   K::B::C::Instance::Arguments  .......       B N         central store for arguments values
   K::B::C::Instance  ..................       B N         central store 4 object ref (4x self + attr ref)
   K::B::C::Registry  ..................         N         central store 4 class definitions and their instances
   K::B::C::Builder::Attribute  ........      MB           create attribute 
   K::B::C::Builder::Method::Arguments        MB           create args object
   K::B::C::Builder::Method::Hook ......      MB           method hook handling
   K::B::C::Builder::Method  ...........      MB           create regular method
   K::B::C::Builder::Accessor  .........      MB           create accessor method 
   K::B::C::Builder::Constructor  ......      MB           create constructor and destructor methods
   K::B::C::Builder  ...................      MB           API to class construction
   K::B::C::Syntax::Signature  .........  C         1.0    convert signature string into data for KBC::Def.::Method::Signature object
   K::B::C::Syntax::Parser  ............         N         define class syntax, API to Keyword::Simple
   K::B::C::Syntax  ....................         N         -
   K::B::Class  ........................   P               root pkg of Kephra OO system (KBOS)
   K::Base  ............................                   root package of self made language extensions
================================================================================
