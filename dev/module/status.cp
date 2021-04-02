Module prototypes are the place to develope libraries (internal API's).
Several connected libraries can be joined in one module proto (list item).
Latest copies of all necessary libraries are copied into a proto before dev takes place.

design of the API's is done in: dev/overview
relation between different types of protos: dev/roadmap.txt
our development model in more details: doc/meta/CellularProgramming.pod

--[legend]----------------------------------------------------------------------
   K ~~ Kephra                            C = Complete
      B ~~ Base                           .P = Partially there, nothing missing now (or only tests)
        C ~~ Class                        . S = Small feature missing
                                          .  U = Usable
                                          .   M = Major feature missing
                                          .    B = Buggy/old Deprecated code
                                          .     I = In Progress (currently worked on)
                                          .      N = Not yet (planned)
--[bed]-------------------------------------------------------------------------
 - Kephra::Base  .......................  C  .....  0.11   symbol maipulation, closures, data, types
 - Kephra::Base::Class .................        I          inside out OO with signatures, interfaces and serialisation
================================================================================
 - Kephra::Base::Object
   Kephra::Base::Object::CodeSnippet
   Kephra::Base::Object::Queue
   Kephra::Base::Object::Store

   #B::Call
   #B::Call::Template
   #B::Call::Dynamic
   #B::Call::Dynamic::Template
--------------------------------------------------------------------------------
    I::Message
    I::Message::Channel
 -  I::Message::Net
--------------------------------------------------------------------------------
    I::Event
 -  I::Event::Table
--------------------------------------------------------------------------------
    I::Command
 -  I::Command::Center
--------------------------------------------------------------------------------
    App::Sizer
 -  App::Panel
--------------------------------------------------------------------------------
 -  App::Bar::Tab
