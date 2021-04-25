*************************************;
* Set path, options and macros      *;
*************************************;
* Set the path to the folder *;
%let path=C:\Users\pestyl\OneDrive - SAS\github repos\Data Projects\Fitbit Competition;

* Import following SAS column naming conventions *;
options validvarname=v7;

* Create a print marco to print the first five rows of a table by default *;
%macro head(tbl,n=5);
    proc print data=&tbl(obs=&n) noobs;
    run;
%mend head;



*************************************;
* Set up graph formatting variables *;
*************************************;

* Color to use for text *;
%let textColor=cx768396;

* Axis label and value size *;
%let AxisLabel=14pt;
%let AxisValue=12pt;
%let TitleSize=16pt;

* Set the title options to the title color and alwyas left justify *;
%let fmtTitle=height=&TitleSize color=&textColor justify=left;

* Set the footnote options to the title color and alwyas left justify *;
%let fmtFootnote=height=8pt color=&textColor justify=left;

* Set the date *;
%let footnoteDate=As of %sysfunc(today(),mmddyy10.);

* Set the x and y axis formatting *;
%let fmtAxes=labelattrs=(size=&AxisLabel color=&textColor)
             valueattrs=(size=&AxisValue color=&textColor);
    
%let fmtXaxis=&fmtAxes;
           
%let fmtYaxis=&fmtAxes;



*************************************;
* ACCESS DATA                       *;
*************************************;
proc import datafile="&path/fitbit.csv"
            out=fitbit_raw(rename=('Start Date'n=Start_Date))
            dbms=csv 
            replace;
run;


%head(fitbit_raw)



*************************************;
* EXPLORE DATA                      *;
*************************************;
* Select only the column info output of PROC CONTENTS *;
ods trace on;
ods select variables;


* View the descriptor portion of the data *;
proc contents data=fitbit_raw;
run;


* View distinct values *;
proc freq data=fitbit_raw;
    tables Type;
run;

* View steps by person *;
proc means data=fitbit_raw min max maxdec=0;
    class Type;
run;



*************************************;
* PREPARE DATA                      *;
*************************************;


*****;
* 1 *;
*****;
* 1. Transpose the data, create columns *;
data fitbit_narrow;
    set fitbit_raw;
    
* New column for the transposed data. Length needs to be the max length of a name *;
    length Person $5;
    retain Week 0;
    
* Create an array to reference each person's name *;
    array col{3}   $  Ryan Peter Kevin ;
    
* Create an array to create the distinct values in the new column when transposing *;
    array name{3} $ name1-name3 ("Ryan" "Peter" "Kevin");
    if Type="Workweek hustle" then Week+1;
       else Day+2;
        
* Loop over one row three times. Output the steps for person-n in the Steps column, and name for person-n in the Person column. *;
* This will run three times for one row and restructure the data *;
    do i=1 to dim(col);
        Person=name[i];
        Steps=col[i];
        output;
    end;
    
* Drop unncessary columns *;
    drop name: i Ryan Peter Kevin;
run;

* Preview the restructured table *;
%head(fitbit_narrow,n=15);


*****;
* 2 *;
*****;
* 2. Determine the weekly placement *;
proc rank data=fitbit_narrow
          out=fitbit_rank
          descending;
    by Start_Date;
    var Steps;
    ranks Place;
run;

%head(fitbit_rank,n=10);


*****;
* 3 *;
*****;
* 3. Determine the winner and winner's steps *;
data fitbit_rank;
    set fitbit_rank;
    if Place=1 then Winner=Person;
        else Winner="Losers";
    if Winner ne "Loser" then WinnerSteps=Steps;
        else WinnerSteps=.;
run;

%head(fitbit_rank,n=10);


*****;
* 4 *;
*****;
* 4. Sort the data *;
proc sort data=fitbit_rank
          out=fitbit_sort;
    by Person Start_date;
run;

%head(fitbit_sort,n=15);


*****;
* 5 *;
*****;
* 5. Create final tables *;
data fitbit_detail(drop=win_streak First Second Third) 
     overall(drop=Start_Date Type Steps Place Day Week win_streak Winner WinnerSteps);
    set fitbit_sort;
    
* Create varialbes to retain through the data step. This will allow them to cumulate *;
    retain win_streak 0 First 0 Second 0 Third 0 total_steps 0 Streak 0;
    
* Create the by group first.Person and last.Person. Use this to cumulate steps, placement and win streak *;
    by Person;
    
* Clear total steps, win streak, first second and third columns when a new person starts *;
    if first.Person then do; 
        total_steps=0;
        win_streak=0;
        Streak=0;
        First=0;
        Second=0;
        Third=0;
    end;
    
* Increase the win streak column for consecutive first places finishes. Clear otherwise *;
    if Place=1 then win_streak+1;
       else win_streak=0;
       
* Store the max win streak in the Streak column *;
    if win_streak>Streak then Streak=win_streak;
    
* Summarize the First, Second and Third place finishes *;
    if Place=1 then First+1;
        else if Place=2 then Second+1;
        else if Place=3 then Third+1;
    
* Increase the cumulative total steps for each person *;
    total_steps+steps;

* Output the rows to the detail table *;
    output fitbit_detail;

* If it's the last row output to the overall table *;
    if last.Person then output overall;
    
* format, label and drop columns *;
    format steps total_steps comma14.;
    label
        total_steps="Total Steps"
        Streak="Win Streak"
        Place="Competition Place"
        Start_date="Start Date"
        First="1st"
        Second="2nd"
        Third="3rd";
run;


* Preview both tables *;
title "Rows in the fitbit_detail table";
%head(fitbit_detail,n=20)

title "Rows in overall table";
%head(overall)

title;


*****;
* 6 *;
*****;
* 6. Add overall points system to overall *;
data overall;
    set overall;
    Points=(First*3)+(Second*1);
run;

* Sort the standings by points descending *;
proc sort data=overall;
    by descending Points;
run;

%head(overall);



*************************************;
* ANALYZE DATA                      *;
*************************************;

* Create attribute map so each individual has a specific color mapped to the distinct value. *;
data attrs;
length linecolor $ 9 fillcolor $ 9;
input ID $ value $ linecolor $ fillcolor $ MarkerColor $;
datalines;
    myid Kevin cx2ecc71 cx2ecc71 cx2ecc71
    myid Peter cx3498db cx3498db cx3498db
    myid Ryan cxf39c12 cxf39c12 cxf39c12
;
run;

title "Individual Colors";
%head(attrs);


data winner;
length linecolor $ 9 fillcolor $ 9;
input ID $ value $ linecolor $ fillcolor $ MarkerColor $;
datalines;
    myid Kevin cx2ecc71 cx2ecc71 cx2ecc71
    myid Peter cx3498db cx3498db cx3498db
    myid Ryan cxf39c12 cxf39c12 cxf39c12
    myid Loser cxd3d3d3 cxd3d3d3 cxd3d3d3
;
run;

title "Winner/Loser Colors";
%head(winner);



************************;
* 1. Overall Standings *;
************************;
ods graphics / width=7in;

title &fmtTitle "Overall Standings";
footnote &fmtFootnote  "&footnoteDate, 1st Place=3pts, 2nd Place=1pts, 3rd Place=0pts";

proc sgplot data=overall
            noborder 
            dattrmap=attrs
            noautolegend;
    hbarparm category=Person response=Points /
          nooutline 
          group=Person
          barwidth=.3
          attrID=myID
           ;
    yaxistable Points First Second Third  Streak Total_Steps /
        y=Person  
        location=inside 
        pad=10
        valueattrs=(size=12pt)
        labelattrs=(color=black weight=bold size=12pt) pad=20;
    yaxis &fmtYaxis display=(nolabel noticks noline);
    xaxis &fmtXaxis display=none;
run;

title;
footnote;

ods graphics / reset;




****************************;
* 2. Winner by Competition *;
****************************;
ods listing gpath="&path";
ods graphics /  width=13in height=5in imagename="test" imagefmt=jpeg;

title &fmtTitle "Winner by Each Competition";
footnote &fmtFootnote  "&footnoteDate";
proc sgpanel data=fitbit_detail
             dattrmap=winner;
    panelby Start_Date / 
        layout=columnlattice
        onepanel
        noheader
        noborder
        nowall;
    vbar Person /
        response=Steps
        group=Winner
        barwidth=.6
        attrID=myID;
    rowaxis display=(nolabel) &fmtXaxis;
    colaxis display=none &fmtYaxis;
    keylegend / 
        position=bottom
        exclude=("Loser")
        noborder
        title=""
        valueattrs=(color=&textColor size=11pt);
run;
title;

ods graphics / reset;



*******************************;
* 3. Cumulative Steps by Week *;
*******************************;
ods graphics / width=9in height=5in;

title &fmtTitle "Cumulative Steps by Person";

proc sgplot data=fitbit_detail
            noborder
            dattrmap=attrs;
    vline Start_date / 
        response=total_steps
        group=Person
        markers
        markerattrs=(symbol=circleFilled size=8)
        lineattrs=(thickness=2)
        attrID=myID;
    keylegend / 
        across=1
        position=topleft
        location=inside
        noborder
        title=""
        valueattrs=(color=&textColor size=11pt);
    yaxis &fmtYaxis display=(nolabel);
    xaxis &fmtXaxis label="Competition Week";
    format Start_Date weekw5.;
run;

title;
footnote;
ods graphics / reset;



*******************************;
* 4. Steps by Competition     *;
*******************************;
ods graphics / width=10in height=5in;

%macro stepsByPerson(competition);

%let clean=%upcase(&competition);

title &fmtTitle "%upcase(&clean) Steps by Competition";
title2 " ";

proc sgpanel data=fitbit_detail
            dattrmap=attrs noautolegend;
    panelby Person / 
        layout=columnlattice 
        novarname
        nowall
        noborder
        headerattrs=(color=&textColor size=12pt weight=bold)
        headerbackcolor=white
        noheaderborder
        spacing=25
    ;
    vbar Week / 
         response=Steps
         attrID=myID group=Person;
    colaxis &fmtYaxis label="Week" display=none;
    rowaxis &fmtXaxis label="Steps";
    where upcase(Type)="&clean";

run;

title;

%mend;


%stepsByPerson(Workweek hustle)

%stepsByPerson(Weekend)