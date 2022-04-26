use v5.16;
use warnings;

use Kephra::Base;

package Kephra::API;

BEGIN {} # because most other modules depend on these symbols the central API has to export first

# :app refs to imortant app parts
sub app          { }
sub app_window   { }
sub doc_panel    { }
sub doc_bar      { }
sub all_doc_bar  { }
sub document     { }
sub all_documents{ }
sub editor       { }

# :log logging
sub error        {  }
sub warning      {  }
sub note         {  }
sub report       {  }

# INIT

1;
