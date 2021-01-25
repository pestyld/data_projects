




****************;
* Set Paths    *;
****************;
%let path=C:\Users\pestyl\OneDrive - SAS\github repos\Data-Projects\Data Visualization;
%let file=Client Tier Share.xlsx;



*******************;
* Import File     *;
*******************;
proc import datafile="&path\&file"
            out=clients
            dbms=excel
            replace;
run;

/*Preview the table*/
proc print data=clients noobs;
run;

/*View descriptor portion*/
ods trace on;
proc contents data=sashelp.cars;
run;

/*Change columns names*/
proc datasets library=work;
    modify clients;
    rename '# of Accounts'n=numAccounts
           '% Accounts'n=pctAccounts
           'Revenue ($M)'n=Revenue 
           '% Revenue'n=pctRevenue;
run;



*************************;
* Exploration           *;
*************************;
proc print data=clients;
run;

proc means data=clients sum;
run;



*************************;
* Data Prep             *;
*************************;
proc format;
    value $tier_fmt
        'A+' = 1
        'A' = 2
        'B' = 3
        'C' = 4
        'D' = 5
        'All other' = 6;
run;


proc transpose data=clients
               out=clients_narrow(rename=(col1=pct _label_=AccountType))
               name=Type;
    by Tier notsorted;
    var pctAccounts pctRevenue;
run;
%macro preview(tbl, n=5);

proc print data=&tbl(obs=&n);
run;

%mend;


%preview(sashelp.cars)

*************************;
* Analyze               *;
*************************;
ods graphics / height=7in;

title j=left c=charcoal h=16pt "Cient Share by Tier";
title2 j=left c=charcoal h=14pt "% of Total";
proc sgpanel data=clients_narrow;
    panelby AccountType /
               novarname 
               noborder 
               nowall 
               noheaderborder 
               headerbackcolor=white
               headerattrs=(color=charcoal size=12pt) 
               spacing=15;
    hbar Tier /
                response=pct
                fillattrs=(color=cx0379cd)
                nooutline
                datalabel 
                datalabelfitpolicy=insidepreferred
                datalabelattrs=(color=white size=14pt weight=bold)
                displaybaseline=off;
    rowaxis labelattrs=(color=cx768396 size=14pt)
            valueattrs=(color=cx768396)
            label="Client Tier";
    colaxis labelattrs=(color=cx768396 size=14pt)
            valueattrs=(color=cx768396)
            label="Percent of Total";
    format pct percent7.;
run;
title;

ods graphics / reset;
