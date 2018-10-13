<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>ltng_CalculateName</fullName>
        <description>Calculates the name for the contact</description>
        <field>Name</field>
        <formula>IF(ISBLANK(FirstName__c),&quot;&quot;,FirstName__c + &quot; &quot;) +
IF(ISBLANK(MiddleName__c),&quot;&quot;,MiddleName__c + &quot; &quot;) +
IF(ISBLANK(LastName__c),&quot;&quot;,LastName__c + &quot; &quot;)</formula>
        <name>Calculate name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Assign Name</fullName>
        <actions>
            <name>ltng_CalculateName</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Assign the Name</description>
        <formula>or(
   ISCHANGED( FirstName__c ),
   ISCHANGED( MiddleName__c ),
   ISCHANGED( LastName__c )
)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
