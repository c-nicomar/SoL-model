function filenameList = getFilenameList( directory, varargin )

if(nargin >= 2)
    stripExtension = varargin{1};
else
    stripExtension = false;
end

if(nargin >= 3)
    extensionSpecifier = ['*.' varargin{2}];
else
    extensionSpecifier = '';
end

% Get the entire contents of the directory
dirContents = dir(fullfile(directory, extensionSpecifier));

% Get rid of any non-file (i.e. directory) entries
fileList = dirContents(~[dirContents(:).isdir]');

% Return just the filenames
filenameList = {fileList(:).name}';

if stripExtension
    % Separate into string before and after period, keeping the former
    filenameList = cellfun(@(x) regexp(x, '^(.*)\.', 'tokens'), filenameList);
end

end

