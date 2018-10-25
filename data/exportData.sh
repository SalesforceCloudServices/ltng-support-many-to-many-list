#!/bin/bash


sfdx force:data:tree:export -d tree -u manyToManyDev -q queries/ltng_M2M_Account__c.txt
sfdx force:data:tree:export -d tree -u manyToManyDev -q queries/ltng_M2M_Contact__c.txt
sfdx force:data:tree:export -d tree -u manyToManyDev -q queries/ltng_M2M_Partner__c.txt
sfdx force:data:tree:export -d tree -u manyToManyDev -q queries/ltng_M2M_Relationship__c.txt

