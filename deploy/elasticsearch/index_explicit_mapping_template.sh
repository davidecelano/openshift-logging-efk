#!/usr/bin/env bash
#
# =======================================
# AUTHOR        : Claudio Prato @Team EA
# CREATE DATE   : 2022/06/13
# PURPOSE       : Setup the es index template
# SPECIAL NOTES :
# =======================================
#
# Tested on Kibana 6.8.1 management
# 
# set -euo pipefail

es_pod=$(oc -n openshift-logging get pods -l component=elasticsearch --no-headers | head -1 | cut -d" " -f1)

oc exec -n openshift-logging -c elasticsearch ${es_pod} -- es_util --query=_template/dedalus_es_template -XPUT -d'
{
    "index_patterns": ["app-*"],
    "settings": {
      "number_of_shards": 2,
      "analysis": {
        "normalizer": {
          "convert_to_uppercase": {
            "type": "custom",
            "char_filter": [],
            "filter": ["uppercase"]
          }
        }
      }
    },
    "version": 1,
    "mappings": {
        "_doc": {
            "_source": { "enabled": true },
            "properties": {
              "structured.@timestamp": {
                  "type": "date",
                  "format": "strict_date_optional_time"
              },
              "structured.application": {
                "type": "text",
                "fields": {
                    "raw": {
                        "type": "keyword",
                        "index": false,
                        "ignore_above": 256
                    }
                }
              },
              "structured.error.message": {
                "type": "text",
                "index": true,
                "norms": false
              },
              "structured.error.stacktrace": {
                "type": "text",
                "norms": false
              },
              "structured.error.type": {
                "type": "text",
                "fields": {
                    "raw": {
                        "type": "keyword",
                        "index": false,
                        "ignore_above": 256
                    }
                }
              },
              "structured.level": {
                "type": "keyword",
                "normalizer": "convert_to_uppercase"
              },
              "structured.location.class": {
                "type": "keyword"
              },
              "structured.location.file": {
                "type": "text",
                "fields": {
                    "raw": {
                        "type": "keyword",
                        "index": false,
                        "ignore_above": 256
                    }
                }
              },
              "structured.location.line_number": {
                "type": "integer",
                "index": false
              },
              "structured.location.method": {
                "type": "keyword"
              },
              "structured.logger_name": {
                "type": "text",
                "fields": {
                    "raw": {
                        "type": "keyword",
                        "index": false,
                        "ignore_above": 256
                    }
                }
              },
              "structured.message": {
                "type": "text",
                "index": true,
                "norms": false
              },
              "structured.thread_name": {
                "type": "keyword",
                "index": false
              },
              "created_at": {
                "type": "date",
                "format": "strict_date_hour_minute"
              }
            }
        }
    }
}'