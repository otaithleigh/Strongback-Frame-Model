function results = responseHistory(obj,gmFile,dt,SF,tEnd,gmID,indexNum)
%% RESPONSEHISTORY Perform response history analysis
%
%   results = RESPONSEHISTORY(obj,gmFile,dt,SF,tEnd,gmID,indexNum)
%       Returns the results of a response history analysis of obj
%       subject to ground motion stored in gmFile with timestep dt
%       scaled by SF. Analysis concludes at tEnd. gmID and indexNum
%       are used for incremental dynamic analyses and are optional
%       if an IDA is not being conducted.
%
%   results has the following fields:
%
%   gmID         -
%   indexNum     -
%   SF           - Scale factor used in the analysis
%   textOutput   - Text output from OpenSees
%   groundMotion - Scaled ground motion used as input
%   displacement   - Time history of the total drift of each story
%   storyShear   - Time history of story shears
%   storyDrift   - Time history of story drifts
%   roofDrift    - Time history of the total roof drift
%   baseShear    - Time history of the base shear
%

% Initialize Results
results = struct;
if nargin < 6
    gmID = '01a';
    indexNum = 1;
else
    results.gmID = gmID;
    results.indexNum = indexNum;
end
results.SF = SF;

% Filenames
filenames.input       = obj.scratchFile(sprintf('%s_responseHistory_input_%s_%i.tcl'      ,class(obj),gmID,indexNum));
filenames.timeSeries  = obj.scratchFile(sprintf('%s_responseHistory_timeSeries_%s_%i.out' ,class(obj),gmID,indexNum));
filenames.nodeCoords  = obj.scratchFile(sprintf('%s_responseHistory_node_coord_%s_%i.out' ,class(obj),gmID,indexNum));
filenames.disp_all    = obj.scratchFile(sprintf('%s_responseHistory_disp_all_%s_%i.out'   ,class(obj),gmID,indexNum));
filenames.energy_disp = obj.scratchFile(sprintf('%s_responseHistory_energy_disp_%s_%i.out',class(obj),gmID,indexNum));
filenames.energy_vel  = obj.scratchFile(sprintf('%s_responseHistory_energy_vel_%s_%i.out' ,class(obj),gmID,indexNum));
filenames.story_disp  = obj.scratchFile(sprintf('%s_responseHistory_story_disp_%s_%i.out' ,class(obj),gmID,indexNum));
filenames.reaction    = obj.scratchFile(sprintf('%s_responseHistory_reaction_%s_%i.out'   ,class(obj),gmID,indexNum));

% Create .tcl file
fid = fopen(filenames.input,'w');

obj.constructBuilding(fid)
if obj.includeExplicitPDelta
    obj.applyGravityLoads(fid)
end

fprintf(fid,'############################### Response history ###############################\n');
fprintf(fid,'timeSeries Path 1 -dt %g -filePath {%s} -factor %g\n',dt,gmFile,SF);
fprintf(fid,'pattern UniformExcitation 1 1 -accel 1\n\n');

fprintf(fid,'#---------------------------------- Recorders ---------------------------------#\n');
fprintf(fid,'recorder Node -file {%s} -time -timeSeries 1 -node 0 -dof 1 accel\n',filenames.timeSeries);
fprintf(fid,'recorder Node -file {%s} -nodeRange 0 %i -dof 1 2 disp\n',filenames.disp_all,8000);
OpenSees.nodeRecorder(fid, filenames.energy_disp, obj.massNodes, 2, 'disp');
OpenSees.nodeRecorder(fid, filenames.energy_vel, obj.massNodes, 1, 'vel');
OpenSees.nodeRecorder(fid, filenames.story_disp, obj.tag('right',1:obj.nStories,1), 1, 'disp');
OpenSees.nodeRecorder(fid, filenames.reaction, [1 1001 2102], 1, 'reaction');
fprintf(fid,'file delete %s\n', filenames.nodeCoords);
fprintf(fid,'print {%s} -node\n', filenames.nodeCoords);


fprintf(fid,'record \n\n');

fprintf(fid,'#---------------------------------- Analysis ----------------------------------#\n');
fprintf(fid,'system UmfPack \n');
fprintf(fid,'constraints %s\n', obj.optionsResponseHistory.constraints.writeArgs());
fprintf(fid,'numberer RCM \n');

fprintf(fid,'OpenSeesComposite::updateRayleighDamping %i %g %i %g\n',...
    obj.optionsResponseHistory.damping_ModeA,obj.optionsResponseHistory.damping_RatioA,...
    obj.optionsResponseHistory.damping_ModeB,obj.optionsResponseHistory.damping_RatioB);

fprintf(fid,'integrator Newmark 0.50 0.25\n');
fprintf(fid,'analysis VariableTransient \n');

fprintf(fid,'set currentTime [getTime]\n');
fprintf(fid,'while { $currentTime < %g } {\n',tEnd);
fprintf(fid,'    algorithm %s\n',obj.optionsResponseHistory.algorithm.type{1});
fprintf(fid,'    test %s\n',obj.optionsResponseHistory.test.writeArgs(1));
fprintf(fid,'    set ok [analyze 1 %g]\n',dt);
for i = 1:length(obj.optionsResponseHistory.test.tolerance)
    if i == 1, k = 2; else, k = 1; end
    for j = k:length(obj.optionsResponseHistory.algorithm.type)
        fprintf(fid,'    if { $ok != 0 } {\n');
        fprintf(fid,'        algorithm %s\n',obj.optionsResponseHistory.algorithm.type{j});
        fprintf(fid,'        test %s\n',obj.optionsResponseHistory.test.writeArgs(i));
        fprintf(fid,'        set ok [analyze 1 %g]\n',dt);
        fprintf(fid,'    }\n');
    end
end
fprintf(fid,'    if { $ok != 0 } {\n');
fprintf(fid,'        exit 2\n');
fprintf(fid,'    }\n');
fprintf(fid,'    set currentTime [getTime]\n');
fprintf(fid,'}\n');

fprintf(fid,'exit 1 \n');
fclose(fid);

% Run OpenSees
[status, result] = obj.runOpenSees(filenames.input);
results.textOutput = result;
switch status
    case 1
        results.exitStatus = 'Analysis Successful';
    case 2
        results.exitStatus = 'Analysis Failed';
    otherwise
        fprintf('%s\n',result);
        error('Analysis Failed in Unknown Manner (exit code: %i)',status);
end

%-------------------------------- Read Results --------------------------------%
temp = dlmread(filenames.timeSeries);
results.time         = temp(:,1);
results.groundMotion = temp(:,2);

temp = dlmread(filenames.story_disp);
results.story_disp_x = temp;

temp = dlmread(filenames.disp_all);
results.disp_x = temp(:, 1:2:end);
results.disp_y = temp(:, 2:2:end);

results.energy_disp_y = dlmread(filenames.energy_disp);
results.energy_vel_x = dlmread(filenames.energy_vel);

coords = OpenSees.readNodeCoords(filenames.nodeCoords, 2);
results.coords_x = coords(:,1)';
results.coords_y = coords(:,2)';

temp = dlmread(filenames.reaction);
results.baseShear = sum(temp,2);

%------------------------------ Computed Results ------------------------------%
storyDrift          = results.story_disp_x;
storyDrift(:,2:end) = storyDrift(:,2:end)-storyDrift(:,1:(end-1));
results.storyDrift  = storyDrift;

results.roofDrift = results.story_disp_x(:,end);

% Clean Folder
if obj.deleteFilesAfterAnalysis
    fields = fieldnames(filenames);
    for i = 1:length(fields)
        delete(filenames.(fields{i}));
    end
end
end %function:responseHistory
