function coords = readNodeCoords(filename, ndm)


coords = NaN(100, ndm);
fid = fopen(filename);
i = 1;

while ~feof(fid)
    gotline = fgetl(fid);

    cstart = strfind(gotline, 'Coordinates  :');

    if isempty(cstart)
        % No coordinates on this line
        continue
    end

    textdata = gotline(cstart+14 : end);
    data = textscan(textdata, '%f');
    data = data{1};
    coords(i,:) = data';
    i = i+1;

end
fclose(fid);

coords(isnan(coords)) = [];

end
