iff %@mid[%@parse[%1]%,3,1]% == 0
  then set temporary = %2
       iff %@len[%temporary% ]% == 1
         then set temporary = *.*
       endiff
       iff %@right[%@parse[%temporary%]%,1]% == 0
         then set temporary = %temporary%*.*
       endiff
       iff %@mid[%@parse[%temporary%]%,4,2]% == 00
         then set file = %temporary%%@file[%1]%
         else iff %@len[%@fileattr[%temporary%]% ]% == 1
                then set file = %@path[%temporary%]%%@newfile[%1 %@file[%temporary%]%]%
                else iff %@fileattr[%temporary%]% == D
                       then set file = %temporary%\%@file[%1]%
                       else set file = %@path[%temporary%]%%@newfile[%1 %@file[%temporary%]%]%
                     endiff
              endiff
       endiff

       iff exist %file%
         then echo File %file% already exists
              inkey Make back-up? %%key
              iff %@upper[%key%]% == Y
                then copy %file% %@path[%file%]%%@newfile[%file% *.BAK]%
              endiff
       endiff
       set key =
       set file =
       set temporary =
endiff
@copy %1 %2
