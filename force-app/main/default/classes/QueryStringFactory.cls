/*********************************************************************************
* Class :          QueryStringFactory
* Test Class :     QueryStringFactoryTest
* Created By :     Anuj Kumar
-----------------------------------------------------------------------------------
* Description : Class to generate the soql query string
-----------------------------------------------------------------------------------
* Version History:
* Version    Developer Name    Date          Detail Features
* 1.0        Anuj              29/09/2021    Initial Development
*
***********************************************************************************/
public class QueryStringFactory {
    
    /*
    *  Constant variables
    */
    public final string SELECT_CLAUSE = 'SELECT ';
    public final string FROM_CLAUSE = ' FROM ';
    public final string ID_FROM_CLAUSE = 'Id FROM ';
    public final string ID_FIELD = ' Id ';
    public final string WHERE_CLAUSE = ' WHERE ';
    public final string ALL_ROWS = ' ALL ROWS ';
    public final string GROUP_BY = ' GROUP BY ';
    public final string HAVING_CLAUSE = ' HAVING ';
    public final string ORDER_BY = ' ORDER BY ';
    public final string LIMIT_CLAUSE = ' LIMIT ';
    public final string OFFSET_CLAUSE = ' OFFSET ';
    public final string WITH_SECURITY_ENFORCED = ' WITH SECURITY_ENFORCED ';
    public final string FOR_UPDATE = ' FOR UPDATE ';
    public final string STANDARD_FIELD = ' FIELDS(STANDARD) ';
    public final string STANDARD_FIELD_WITH_FROM = ' FIELDS(STANDARD) FROM ';
    public final string ASCENDING = ' ASC ';
    public final string DESCENDING = ' DESC ';
    public final string EMPTY_STRING = '';
    public final string SOQL_QUERY_LIMIT_EXCEED = 'You have reached the maximum no of SOQL query in single transaction.';

    public final string COMMA = ',';

    public static Boolean isUpdateable = false;
    public static Boolean isRecordLocking = false;
    public static Boolean isSecurityEnforced = false;

    public string objectName;

    public string queryString = SELECT_CLAUSE;

    public QueryDetails qd;

    /*
    *  Parameter : 'objectApiName' - We need to set the sObject API Name.
    *  Example : QueryStringFactory qsf = new QueryStringFactory('Account');
    *  Return : null
    *  Description : Method will take Object API Name as parameter and constract a query with Id field only.
    */
    public QueryStringFactory(String objectApiName) {
        qd = new QueryDetails();
        
        if(String.isNotBlank(objectApiName)){
            qd.objectName = objectApiName;
            qd.fields = ID_FIELD;
        }
    }
    
    /*
    *  Parameter : 'objectApiName' - We need to set the sObject API Name, 'setOfFields' - Set<string> fields = new Set<string> {'Name'};
    *  Example : QueryStringFactory qsf = new QueryStringFactory('Account', fields);
    *  Return : null
    *  Description : Method will take Object API Name as parameter and construct a query with Set of fields from second parameter.
    */
    public QueryStringFactory(String objectApiName, Set<String> setOfFields) {
        qd = new QueryDetails();
        qd.objectName = objectApiName;

        if(String.isNotBlank(objectApiName) && setOfFields != null){
            if(isUpdateable){
                set<string> updatableFields = new set<string>();
                for(SObjectField field : Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap().values()){
                    Schema.DescribeFieldResult fieldDesc = field.getDescribe();
                    if(setOfFields.contains(fieldDesc.getName()) && fieldDesc.isUpdateable()){
                        updatableFields.add(fieldDesc.getName());
                    }
                }
                qd.fields = joinToString(updatableFields, COMMA);
            }else{
                qd.fields = joinToString(setOfFields, COMMA);
            }
        }
        
    }
    
    
    /*
    *  Parameter : 'objectApiName' - We need to set the sObject API Name, 'standardFields' - if need to include all the standard fields, 'customFields' - if need to include all the custom fields
    *  Example : QueryStringFactory qsf = new QueryStringFactory('Account', true, true);
    *  Return : null
    *  Description : Method will take Object API Name as a first parameter and second parameter to include all standard field and third parameter is used to inculde all custom fields in query.
    */
    public QueryStringFactory(String objectApiName, Boolean standardFields, Boolean customFields) {
        qd = new QueryDetails();
        qd.objectName = objectApiName;

        string allCustomField = '';
        if(String.isNotBlank(objectApiName) && customFields){
            set<string> allCustomeFieldSet = new set<string>();
            for(SObjectField field : Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap().values()){
                Schema.DescribeFieldResult fieldDesc = field.getDescribe();
                if (fieldDesc.isCustom()) {
                    if(isUpdateable && fieldDesc.isUpdateable()){
                        allCustomeFieldSet.add(fieldDesc.getName());
                    }else{
                        allCustomeFieldSet.add(fieldDesc.getName());
                    }
                }
            }
            if(!allCustomeFieldSet.isEmpty()){
                allCustomField = joinToString(allCustomeFieldSet, COMMA);
            }
        }
        if(String.isNotBlank(objectApiName) && standardFields && customFields && String.isNotBlank(allCustomField)){

            qd.fields = STANDARD_FIELD + COMMA + allCustomField;
        }else if(String.isNotBlank(objectApiName) && standardFields && !customFields){

            qd.fields = STANDARD_FIELD;
        }else if(String.isNotBlank(objectApiName) && !standardFields && customFields){

            qd.fields = allCustomField;
        }else if(String.isNotBlank(objectApiName) && !standardFields && !customFields){

            qd.fields = ID_FIELD;
        }
    }
    
    /*
    *  Parameter : 'innerQuerySet' - we need to set the set of string as inner query format.
    *  Example : Set<string> fields = new Set<string> {'Name'};
    *            QueryStringFactory qsf = new QueryStringFactory('Account', fields);
    *            qsf.addInnerQuery(new Set<string> {'(Select Id, Name from Contacts)'});
    *  Return : null
    *  Description : Method will take set of string parameter as input and add them to inner query.
    */
    public void addInnerQuery(Set<String> innerQuerySet){
        if(!innerQuerySet.isEmpty()){
            qd.innerQuery = COMMA + joinToString(innerQuerySet, COMMA);
        }
    }
    
    
    /*
    *  Parameter : 'whereClauseData' - Instance of FilterClauseWrapper wrapper class and 'includeDeletedRecords' - if need to fetch the records from recycle bin.
    *  Example : QueryStringFactory.FilterClauseWrapper wrap = new QueryStringFactory.FilterClauseWrapper();
    *            wrap.filterLogic = '({0})';
    *            wrap.filters = new Set<String> {'Phone != null'};
    *            Set<string> fields = new Set<string> {'Name'};
    *            QueryStringFactory qsf = new QueryStringFactory('Account', fields);
    *            qsf.addWhereClause(wrap, false);
    *  Return : null
    *  Description : Method is used to construct a where clause of a query.
    */
    public void addWhereClause(FilterClauseWrapper whereClauseData, Boolean includeDeletedRecords){
        
        if(whereClauseData != null && whereClauseData.filterLogic != null && whereClauseData.filters != null){

            string whereClause = String.format(whereClauseData.filterLogic, new List<string>(whereClauseData.filters));
            qd.whereClause = whereClause;
            qd.includeDeletedRecords = includeDeletedRecords;
        }

        if(includeDeletedRecords){
            queryString +=  ALL_ROWS;
        }
    }
    
    /*
    *  Parameter : 'setOfFields' - set of fields with which we need to do group by.
    *  Example : 
    *            Set<string> fields = new Set<string> {'Name'};
    *            QueryStringFactory qsf = new QueryStringFactory('Account', fields);
    *            qsf.addGroupBy(new Set<string> {'Name'});
    *  Return : null
    *  Description : Method is used to add a Group By clause in a query.
    */
    public void addGroupBy(Set<String> setOfFields){
        qd.groupBy = joinToString(setOfFields, COMMA);
    }
    
    /*
    *  Parameter : 'havingClauseData' - Instance of FilterClauseWrapper wrapper class.
    *  Example : QueryStringFactory.FilterClauseWrapper wrap = new QueryStringFactory.FilterClauseWrapper();
    *            wrap.filterLogic = '({0})';
    *            wrap.filters = new Set<String> {'Industry != null'};
    *            Set<string> fields = new Set<string> {'Industry', 'COUNT(Id)'};
    *            QueryStringFactory qsf = new QueryStringFactory('Account', fields);
    *            qsf.addGroupBy(new Set<string> {'Industry'});
    *            qsf.addHavingClause(wrap);
    *  Return : null
    *  Description : Method is used to add a Having clause in a query.
    */
    public void addHavingClause(FilterClauseWrapper havingClauseData){
        if(havingClauseData != null && havingClauseData.filterLogic != null && havingClauseData.filters != null){

            string havingClause = String.format(havingClauseData.filterLogic, new List<string>(havingClauseData.filters));
            qd.havingClause = havingClause;
        }
    }
    
    /*
    *  Parameter : 'isASC' - get the record in Ascending order, 'isDESC' - get the record in descending order, 'setOfFields' - get the record with 
    *  Example : Set<string> fields = new Set<string> {'Name'};
    *            QueryStringFactory qsf = new QueryStringFactory('Account', fields);
    *            qsf.addOrderBy(false, true, new Set<string> {'Name'});
    *  Return : null
    *  Description : Method is used to add a Order By clause in a query.
    */
    public void addOrderBy(Boolean isASC, Boolean isDESC, Set<String> setOfFields){
        qd.orderBy = joinToString(setOfFields, COMMA) + (isASC ? ASCENDING : EMPTY_STRING) + (isDESC ? DESCENDING : EMPTY_STRING);
    }
    
    
    /*
    *  Parameter : 'numberOfRowsToReturn' - no of record that the return from SOQL query (If available)
    *  Example : Set<string> fields = new Set<string> {'Name'};
    *            QueryStringFactory qsf = new QueryStringFactory('Account', fields);
    *            qsf.addLimit(1);
    *  Return : null
    *  Description : Method is used to add a Limit in a query.
    */
    public void addLimit(Integer numberOfRowsToReturn){
        qd.limitClause = EMPTY_STRING + numberOfRowsToReturn;
    }
    
    /*
    *  Parameter : 'numberOfRowsToSkip' - no of record that we want to skip from the return result
    *  Example : Set<string> fields = new Set<string> {'Name'};
    *            QueryStringFactory qsf = new QueryStringFactory('Account', fields);
    *            qsf.addOffSet(5);
    *  Return : null
    *  Description : Method is used to add a Offset in a query.
    */
    public void addOffSet(Integer numberOfRowsToSkip){
        qd.offSetClause = EMPTY_STRING + numberOfRowsToSkip;
    }
    
    
    /*
    *  Parameter : 
    *  Example : Set<string> fields = new Set<string> {'Name'};
    *            QueryStringFactory qsf = new QueryStringFactory('Account', fields);
    *            qsf.query();
    *  Return : 'SELECT ID, Name from Account'
    *  Description : Method is used to construct a query string with all specified values.
    */
    public string query(){

        string query = SELECT_CLAUSE + qd.fields;

        if(STRING.isNotBlank(qd.innerQuery)){
            query += qd.innerQuery;
        }

        query += FROM_CLAUSE + qd.objectName;

        if(STRING.isNotBlank(qd.whereClause)){
            query += WHERE_CLAUSE + qd.whereClause;
        }

        if(isSecurityEnforced){
            query += WITH_SECURITY_ENFORCED;
        }

        if(STRING.isNotBlank(qd.groupBy)){
            query += GROUP_BY + qd.groupBy;
        }
        
        if(STRING.isNotBlank(qd.havingClause)){
            query += HAVING_CLAUSE + qd.havingClause;
        }

        if(STRING.isNotBlank(qd.orderBy)){
            query += ORDER_BY + qd.orderBy;
        }

        if(STRING.isNotBlank(qd.limitClause)){
            query += LIMIT_CLAUSE + qd.limitClause;
        }

        if(STRING.isNotBlank(qd.offSetClause)){
            query += OFFSET_CLAUSE + qd.offSetClause;
        }

        if(isRecordLocking && STRING.isBlank(qd.groupBy) && STRING.isBlank(qd.havingClause)){
            query += FOR_UPDATE;
        }

        if(qd.includeDeletedRecords && !isRecordLocking){
            query += ALL_ROWS;
        }
        
        if(Limits.getQueries() >= Limits.getLimitQueries()){
            
            return SOQL_QUERY_LIMIT_EXCEED;
        }
        
        return string.isNotBlank(query) ? query : null;
    }

    /*
    *  Method is used to join a set of string with Join keyword
    */
    public string joinToString(set<string> setOfStringValues, string joinKeyword){
        return STRING.join(new List<String>(setOfStringValues), joinKeyword);
    }

    public class FilterClauseWrapper {

        public string filterLogic;
        public set<string> filters;
    }

    public class QueryDetails {

        public string objectName;
        public string fields;
        public string innerQuery;
        public string whereClause;
        public string groupBy;
        public string havingClause;
        public string orderBy;
        public string limitClause;
        public string offSetClause;

        public boolean includeDeletedRecords;

    }

}