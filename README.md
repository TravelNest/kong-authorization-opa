# OPA Kong Plugin
This plugin is a fairly light touch and simply forms the data into an appropriate shape and throws it towards an endpoint - technically no more than that - though it's intended use is to fire requests to [OPA](https://www.openpolicyagent.org/) and respond appropriately (401 for unauthorized and continue with the request otherwise).
