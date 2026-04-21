# Market-Basket-Analysis
DATA SHAPE:
how many orders =
how many products =
Obvious problems = Missing CUstomerID

PROFILING
-Look for pairs that show up together most times; 
would a customer expect this to go together?

CLEANING:
-Product Names means samething everytime they show up
-No duplicates
-removed: cancelled orders, negative quantity, zero/negative price, letters-only stockcode

DATA SHAPING;
Put the data into tidy structure I can reuse e.g.
orders, and what was bought together.

ANALYZING; 
Finding out the products that are more likely to come together. 

PRESENTATION;
-A short list of “top product pairs” that make obvious bundle ideas.
-A simple pattern view that shows which items “pull” others with them.
-Three bundle suggestions with one‑line reasons a customer would say “yes”.
-One small note: where these patterns come from and what you didn’t do (yet), in a single line.
-One headline on top of each view that states the point first.

