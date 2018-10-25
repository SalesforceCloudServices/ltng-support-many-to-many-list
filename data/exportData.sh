#!/bin/bash


sfdx force:data:tree:export -d tree -u manyToManyDev -q queries/ltng_M2M_Account__c.txt
sfdx force:data:tree:export -d tree -u manyToManyDev -q queries/ltng_M2M_Contact__c.txt
sfdx force:data:tree:export -d tree -u manyToManyDev -q queries/ltng_M2M_Relationship__c.txt

sfdx force:data:soql:query -q "$(< queries/ltng_M2M_AccountContactRelationship__c.txt)" --json | JSON > tree/ltng_M2M_AccountContactRelationship__c.json
sfdx force:data:soql:query -q "$(< queries/ltng_M2M_Partner__c.txt )" --json | JSON > tree/ltng_M2M_Partner__c.json

