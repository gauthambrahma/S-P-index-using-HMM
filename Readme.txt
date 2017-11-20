Approach used to develop the model and Formal description:

Data is downloaded from yahoo finance website for 1 year and the column indicating the closing prices is read. Depending on
the moving average we transform the closing prices to a sequence of observables.The states are “Flat”, “Uptrend” and
 “Downtrend”.  And the output symbols are “High” “Low” and “same”. 

A={ “Flat”, “Uptrend”, “Downtrend”}

B={ "High” “Low” , “same”}

"High" is when the price is more than (1+0.001) times moving average 
"Low" is when the price is less than (1-0.001) times moving average 
"Same" is when the price is between (1-0.001) times moving average  and (1+0.001) times moving average 

"uptrend" is when the movement of closing prices are in upward direction. It means more highs than lows in terms of symbols
"Downtrend" is when the movement of closing prices are in downward direction.It means more lows than highs in terms of symbols
"Flat" is when the upward and downward directions are balanced and the net rise and fall is not substantial. It means almost equal 
number of lows and highs. 
In each of these states the symbol 'same' means that the slope of the closing prices graph will be the same as observed. 

Note:Numerically we represent the these states and symbols using 1,2,3 wherever needed by matlab.

We manually calculate the initial Transmission and 
emmision matrices. They are as follows

                                         'Uptrend'   'Downtrend'  'Flat'
                           'Downtrend'     1/3         1/3          1/3
                     
Guess Transmission Matrix= 'Flat'          1/3         1/3          1/3

                           'Uptrend'       1/3         1/3          1/3

In the above transmission matrix we assume that there is equal probability to go from any state to any state.


                                           'Low'      'Same'        'High'
                            'Downtrend'     2/3         1/3          0
                     
Guess Emission Matrix=      'Flat'          1/3         1/3          1/3

                            'Uptrend'         0         1/3          2/3

In the above Emission Matrix consider the first row.
The current state is Downtrend. There is more chance to emmit low because a low is emmited if the previous state is 
either flat or uptrend. If the previous state is Downtrend then same is emmited. and there is no scenario in which a
high is emitted hence we consider the three probabilities as 2/3,1/3,0. The reverse is true for uptrend. 
Now for the flat a low is emmited when comming from uptrend. A high is emitted when comming from downtrend and same when coming 
from flat. Hence there is an equal probability for all the symbols. 

Note:The initial probabilites will not have much impact on final transmission and Emission matrices but it makes sense to not take them
at random.

The next up is feeding the Observables, Guess Transmission Matrix and Guess Emission Matrix to hmmtrain. This method runs BaumWelch algorithm
which looks at the sequence and tunes the Transmission and Emission probabilities. 

Posterior probabilities of the states are calculated by using hmmdecode. The last column will give us how likely is each state to be the active 
state in that moment. The state with maximum probability is the state the machine is likely to be in that moment. Hence from that state we multipy 
with the transision probabilities and then from that we multiply the corresponding emmisions for each state in transmission and emmision matrices 
respectively. The symbol with maximum probability is the symbol most likely to be emitted. we add it to the observable and repeat the process for
next 9 symbols as well

Finally we reverse map the symbols to closing prices and plot the graph