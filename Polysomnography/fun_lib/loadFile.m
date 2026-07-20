function dataFiles = loadFile(dirData,strng,position)
% - strng: is a string which defines the files to load
% - position ('start' of 'end'): define where strng is located in the file
%   name

    files = dir(dirData);
    if strcmp(position, 'start')
        dataFiles = files(cell2mat(cellfun(@(x) startsWith(x,strng),{files.name},'UniformOutput',0)));
    else 
        dataFiles = files(cell2mat(cellfun(@(x) endsWith(x,strng),{files.name},'UniformOutput',0)));
    end 
end