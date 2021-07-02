function h = getfhandle(name)

%GETFHANDLE Obtain a function handle for a private function.
%   GETFHANDLE(NAME) returns a handle to the function specified by NAME.
%   It obtains this by changing to the directory containing NAME obtaining
%   the handle, and returning to the the original directory.


%% Locate the function
w = which(name, '-all');
assert(~isempty(w), 'Could not find "%s".', name);

%% Store this directory, and the directory containing the name
d1 = pwd;
d2 = fileparts(w{1});

%% CD to the other directory, get the handle, then come back
try
    cd(d2);
    h = str2func(name);
    cd(d1);
catch
    cd(d1);
    error('Could not properly obtain handle.');
end
