# Dynamic DOQL Builder Class

# Sample Code to run

Set<string> fields = new Set<string> {'Id', 'Name', 'Phone', 'AccountNumber', 'Custom_Field__c'};

QueryStringFactory.isUpdateable = true;
QueryStringFactory.FilterClauseWrapper wrap = new QueryStringFactory.FilterClauseWrapper();
wrap.filterLogic = '({0})';
wrap.filters = new Set<String> {'Phone != null'};
QueryStringFactory.isRecordLocking = true;
QueryStringFactory.isSecurityEnforced = true;
QueryStringFactory qsf = new QueryStringFactory('Account', fields);
qsf.addLimit(1);
qsf.addInnerQuery(new Set<string> {'(Select Id, Name from Contacts)'});
qsf.addWhereClause(wrap, false);
qsf.addOffSet(0);
string query = qsf.query();

system.debug('== Final query string '+query);

