
import javascript

// Identifies locations where an environment variable is read

from DataFlow::Node source
where
  source =
    DataFlow::globalVarRef("process")
      .getAPropertyRead("env")
      .getAPropertyRead()
select
  source, "environment variable source"
