%Author:Gautham Ponnaganti
%Short Description: The model takes two colums as input one is closing
%prices and other is the date. It converts the colsing prices into a set of
%observables based on suggesions. Then it trans the model to get the
%transmission and emission probabilities. Then it calulates posterior
%probabilities for states through which it predicts the future states and
%sequences. It reverse maps the symbols to closing prices and plots it
%against date.


%Getting the count of rows and columns
Temp=csvread('table.csv',1,0);
[nRows,nCols] = size(Temp);
table=readtable('table.csv');
dates=table(1:end,1);
dates=flipud(dates);

%converting it into readable format and taking only closing prices
format long g;
InputT=csvread('table.csv',1,4,[1 4 nRows 4]);
InputT=single(InputT);
Input=flipud(InputT);
MovingAvg=zeros(5,1);

%Computing the moving average
lag=5;
for i=5:size(Input)
    last5Values=Input(i-4:i);
    MovingAvg=[MovingAvg;sum(last5Values)/5];
end

%creating a set of observables
for i=5:size(Input)
    if Input(i)<(1-0.001)*MovingAvg(i)
        Observables(i-4)='L';
      %  Observables_numeric(i)=1;
    elseif Input(i)>(1+0.001)*MovingAvg(i)
        Observables(i-4)='H';
       % Observables_numeric(i)=3;
    else
        Observables(i-4)='S'; 
       % Observables_numeric(i)=2;
    end
end
%disp(Observables);

%trying to get estimates of transmission and emission probabilities
SeqSymbols=['L','S','H'];
States=['D','F','U'];

TRGuess=[1/3,1/3,1/3;1/3,1/3,1/3;1/3,1/3,1/3];
EMIGuess=[2/3,1/3,0;1/3,1/3,1/3;0,1/3,2/3];

[TREsti,EMIEsti]=hmmtrain(Observables,TRGuess,EMIGuess,'Symbols',SeqSymbols);
 NewSymbols=[];
 NewStates=[];
 
%The below loop will generate next 10 observables
for i=1:10
    %calculating the posterior probabilities
    PStates=hmmdecode(Observables,TREsti,EMIEsti,'Symbols',SeqSymbols);
    PStatesLastColumn=PStates(:,end);
    %finding max of the last column
    [MaxOfColumn,indexOfMax]=max(PStatesLastColumn);
    %obtaining the current state from posterior probabilities of states
    %mapping it to transition and emmission matrices to get the max and 
    %to determine what will the next transmission state be and emitted
    %symbol be
    currentPState=PStatesLastColumn(indexOfMax,:);
    resultForThisRun=currentPState*TREsti(indexOfMax,:);
    resultForThisRun1=resultForThisRun(1)*EMIEsti(1,:);
    resultForThisRun2=resultForThisRun(2)*EMIEsti(2,:);
    resultForThisRun3=resultForThisRun(3)*EMIEsti(3,:);
    finalResult=[resultForThisRun1;resultForThisRun2; resultForThisRun3];
    [maxSymbol,imaxSymbol]=max(finalResult(:));
    [I_Row,I_Column]=ind2sub(size(finalResult),imaxSymbol);
    NextState=States(I_Row);
    NextSymbol=SeqSymbols(I_Column);
    %emitted symbol will now be a part of the observable
    Observables=[Observables,NextSymbol];   
    NewSymbols=[NewSymbols,NextSymbol];
    NewStates=[NewStates,NextState];
end

pcl=[];

%reverse engineering the closing prices from our emissions above
for i=1:numel(NewSymbols)
    currentMA=MovingAvg(end);
    if(NewSymbols(i)=='H')
        currentClosePrice=currentMA*(1.001);
    elseif(NewSymbols(i)=='L')
        currentClosePrice=currentMA*(0.999);
    elseif(NewSymbols(i)=='S')
        currentClosePrice=currentMA*1;
    end
    Input=[Input;currentClosePrice];
    %computing the new moving average
    last5Values=Input(numel(Input)-4:numel(Input));
    MovingAvg=[MovingAvg;sum(last5Values)/5];
    pcl=[pcl currentClosePrice];
end

%extending date range for X-Axis
datesFormat=datetime(dates.Date,'InputFormat','yyyy-MM-dd');
for i=1:10
   temporary=datenum(datesFormat(end));
   newDate=addtodate(temporary,1,'day');
   datesFormat=[datesFormat;datestr(newDate)];
end

%for the the state graph applying veterbi algorithm to get the most 
%probable state path that is likely to have produced the emissions
StatesPath=hmmviterbi(Observables,TREsti,EMIEsti,'Symbols',SeqSymbols);
StatesPath=100.*StatesPath+1400;
for h=1:4
   StatesPath=[StatesPath StatesPath(end)];
end

%******UNCOMMENT ANY TO CHECH THE VALIDITY OF MODEL*********
%displaying the model 
%disp(size(displayStates));
%disp(size(datesFormat));
%StatesPath=rot90(StatesPath);
% disp('States:');
% disp(States);
% fprintf('\n');
% disp('Symbols:');
% disp(SeqSymbols);
% fprintf('\n');
% disp('Transmission Matrix:');
% disp(TREsti);
% fprintf('\n');
% disp('Emission Matrix:');
% disp(EMIEsti);
% fprintf('\n');
% disp('The next 10 states:');
% disp(NewStates);
% fprintf('\n');
% disp('The next 10 symbols emitted:');
% disp(NewSymbols);
% fprintf('\n');
 disp('The next 10 closing prices:')
 disp(pcl);

%plotting the graph 
plot(datesFormat(1:end-10),Input(1:end-10),datesFormat(end-10:end),Input(end-10:end),datesFormat,StatesPath);
title('Hidden Markov Model');
xlabel('Time');
ylabel('Closing Price');
legend('Test Data','Forecast','States(Down=Downtrend, Middle=Flat,Up=Uptrend)','Location','north');
