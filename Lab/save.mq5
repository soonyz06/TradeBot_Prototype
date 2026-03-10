         if(Price[1].close>Upper[1]){
            if(sellPosition==0)
            executeSellStop(Upper[0]);
         }
         if(Price[1].close<Lower[1]){
            if(buyPosition==0)
            executeBuyStop(Lower[0]);
         }