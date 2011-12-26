Program add;

var
inputFile, outputFile: text;
a, b, total: longint;

begin
	assign(inputFile, 'add.in');
	assign(outputFile, 'addout.txt');
	reset(inputFile);
	rewrite(outputFile);

	readln(inputFile,a,b);
	total := a + b;
	writeln(outputFile,total);

	close(inputFile);
	close(outputFile);
end.

