(* pascal program to drive ERASE - an external routine which *)
(* allows pascal programs to erase files via cp/m's file     *)
(* system.                                                    *)

program erase_driver;

	type
		filename = string 14;
		$string0 = string 0;
		$string1 = string 1;
		$string255 = string 255;
	var
		i       : integer;
		oldfile : filename;
		newfile : filename;
		typefile :filename;
 
 


 
	function
		erase(oldfilen:filename):boolean;external;

     (* main program driver *)
	begin
		while (true) do
		begin
		     (* old file name *)
			writeln('enter name of file to be erased');
			readln(oldfile);
		     

			if erase(oldfile)
				then writeln('file erased')
				else writeln('failed deleting')
		end
	end.
                                                                                                                 