****************************;
* Set Paths and Options    *;
****************************;

* Location and file name set in macro variables *;
%let path=&path\github repos\Data Visualization\Covid Scams;
%let filename=Title_State_Full_Data_data.csv;

* Variable names follow SAS naming rules *;
options validvarname=v7;



****************************;
* Access Data              *;
****************************;

* Import CSV file *;
proc import datafile="&path./&filename"
            out=covidScamsRaw
            dbms=csv
            replace;
    guessingrows=max;
run;



****************************;
* Explore Data             *;
****************************;

* View column names, label names, and data type *;
proc contents data=covidScamsRaw varnum;
run;

* Print the first 20 rows of the raw data *;
proc print data=covidScamsRaw(obs=20) noobs;
run;



****************************;
* Data Preparation         *;
****************************;

* Sort the data by state and keep necessary columns. Only keep: 
  - the state name (Consumer_State_Name_Cleansed)
  - total number of fraud cases by that state (State_Total_Reports) *;
  
proc sort data=covidScamsRaw(keep=Consumer_State_Name_Cleansed State_Total_Reports)
          out=covidScamsSort 
          nodupkey;
    by Consumer_State_Name_Cleansed;
run;

* Rename the columns *;
data covidScams;
    set covidScamsSort;
    rename Consumer_State_Name_Cleansed=State
           State_Total_Reports=TotalReports;
run;


* Obtain the geographic coordinates for state using the mapsgfk.us_states_attr *;
* 3 Steps:
    1. Preview the lookup tables
    2. Create a view with State abbreviations
    3. Create a table with the geographic coordinates called covidScamsFinal 
    
* 1. Preview the lookup tables *;

* State abbreviation table *;
proc print data=mapsgfk.us_states_attr (obs=5);
    var idName Statecode;
run;

* State center geographic coordinates *;
proc print data=mapsgfk.uscenter_all (obs=5);
    var Lat Long StateCode;
run;


* 2. Join the lookup table to obtain State abbreviations *;
proc sql;
create table CovidScamsLookup as
select c.*, 
       ifc(us.StateCode="","PR",us.StateCode) as StateCode /* Puerto Rico is not in the lookup table. Will return missing. Condition will return PR for missing*/
    from covidScams as c left join
         mapsgfk.us_states_attr as us
    on c.State = us.idName;
quit;

* Preview the new table *;
proc print data=CovidScamsLookup (obs=5) noobs;
run;


* 3. Create the final table that contains the center geographic coordinates for each State *;
proc sql;
create table covidScamsFinal as
select v.State, v.StateCode, 
       max(TotalReports) as TotalReports format=comma14., min(c.Lat) as Lat, min(c.Long) as Long
    from CovidScamsLookup as v left join
         mapsgfk.uscenter_all as c
    on v.StateCode = c.StateCode
    group by v.State, v.StateCode;
quit;

* Preview the table with geographic coordinates *;
proc print data=covidScamsFinal (obs=5) noobs;
run;




****************************;
* Plot the Data            *;
****************************;

* Default *;
ods graphics / height=7in;

proc sgmap plotdata=covidScamsFinal;
    esrimap url="http://services.arcgisonline.com/arcgis/rest/services/Canvas/World_Light_Gray_Base";
    bubble x=Long y=Lat size=TotalReports;
run;
title;

ods graphics / reset;


* Adjust Bubble size *;
ods graphics / height=7in;

proc sgmap plotdata=covidScamsFinal;
    esrimap url="http://services.arcgisonline.com/arcgis/rest/services/Canvas/World_Light_Gray_Base";
    bubble x=Long y=Lat size=TotalReports / 
                 bradiusmax=13pt bradiusmin=1pt;
run;
title;

ods graphics / reset;




****************************;
* Final Visualization      *;
****************************;

proc sort data=covidScamsFinal
          out=covidScamsTop5Sorted;
    by descending TotalReports;
run;

data CovidScamsTop5;
    set covidScamsTop5Sorted;
    if _n_ <= 5 then do;
        Top5 = "Yes";
        Top5Name=catx(" ",State,put(TotalReports,comma16.));
    end;
    else do;
        Top5 = "No";
        Top5Name="";
    end;
run;






proc template;
    define style styles.myStyle;
    parent=styles.htmlblue;
***************** Modify Group Graph Colors *****************;
    class GraphColors /  
       /*FILL COLORS*/
           'gdata1' = cx0379cd
           'gdata2' = cxa6a4a4;
***************** Modify Graph Outlines *****************;
    class GraphOutlines /
            LineThickness=0px;
    end;
run;


ods _all_ close;

ods listing gpath="&path"
            style=myStyle;

* Make the default output the following *;
ods html5 (id=web) style=myStyle;

ods graphics / height=8in outputfmt=jpeg imagename="Covid Scams by State";


title height=20pt justify=left color=charcoal "Top 5 States with Covid Fraud Reported";
proc sgmap plotdata=CovidScamsTop5;
    esrimap url="http://services.arcgisonline.com/arcgis/rest/services/Canvas/World_Light_Gray_Base";
    bubble x=Long y=Lat size=TotalReports / 
                 bradiusmax=13pt bradiusmin=1pt
                 group=Top5
                 datalabel=Top5Name
                 datalabelpos=left
                 datalabelattrs=(size=12pt weight=bold color=cx0379cd);
run;
title;

ods graphics / reset;



/* title "State Population Estimates by State"; */
/* proc sgmap mapdata=mapsgfk.us */
/*            maprespdata=CovidScamsTop5; */
/*     choromap TotalReports /  */
/*                     id=StateCode  */
/*                     mapid=StateCode; */
/* run; */
/* title; */