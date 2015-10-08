@a=(4,6,1,0,0,1);sub range{(shift @a)..(shift @a)}print range();while(@a){print scalar(range())}
### RESULT:456123E0
