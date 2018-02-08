function results = pushover(obj,F,type,varargin)
%% PUSHOVER Perform a pushover analysis
%
%   results = PUSHOVER(obj,F,type,typeArg) performs a pushover
%       analysis with load distribution specified by F and end
%       condition defined by type and typeArg.
%
%   type accepts the following options:
%       targetDrift
%       targetPostPeakRatio
%
%   results has the following fields:
%
%   F                       Force ratios
%   targetDrift             Target drift for analysis
%   targetPostPeakRatio     Target post peak ratio
%   textOutput              Console output from OpenSees
%   exitStatus              Reports whether analysis was successful
%   totalDrift              Time history of total drift of stories
%   storyShear              Time history of story shears
%   storyDrift              Time history of story drifts
%   appliedStoryForce       Time history of applied forces
%   roofDrift               Time history of total roof drift
%   baseShear               Time history of base shear
%

assert(isnumeric(F) && isvector(F) && (length(F) == obj.nStories),...
    'F should be a numeric vector of length %i (number of stories)',obj.nStories);
if iscolumn(F)
    F = F';
end

% Initialize Results
results = struct;
results.F = F;

switch lower(type)
    case 'targetdrift'
        targetDrift      = varargin{1};
        results.targetDrift = targetDrift;
    case 'targetpostpeakratio'
        targetPostPeakRatio = varargin{1};
        results.targetPostPeakRatio = targetPostPeakRatio;
    otherwise
        error('Unknown analysis type: %s',type);
end

% Filenames
filenames.input         = obj.scratchFile(sprintf('%s_pushover_input.tcl',      class(obj)));
filenames.timeSeries    = obj.scratchFile(sprintf('%s_pushover_timeSeries.out', class(obj)));
filenames.disp_all      = obj.scratchFile(sprintf('%s_pushover_disp_all.out',   class(obj)));
filenames.story_disp    = obj.scratchFile(sprintf('%s_pushover_story_disp.out', class(obj)));
filenames.nodeCoords    = obj.scratchFile(sprintf('%s_pushover_node_coord.out', class(obj)));
filenames.base_shear    = obj.scratchFile(sprintf('%s_pushover_base_shear.out', class(obj)));
filenames.local_brace   = obj.scratchFile(sprintf('%s_pushover_local_brace.out', class(obj)));
filenames.local_sback   = obj.scratchFile(sprintf('%s_pushover_local_sback.out', class(obj)));


%############################## Create .tcl file ##############################%
fid = fopen(filenames.input,'w');

obj.constructBuilding(fid)
if obj.includeExplicitPDelta
    obj.applyGravityLoads(fid)
end

fprintf(fid,'################################### Pushover ###################################\n');
fprintf(fid,'timeSeries Linear 1\n');
fprintf(fid,'pattern Plain 1 1 {\n');
for i = 1:obj.nStories
    if F(i) ~= 0
        fprintf(fid,'    load %i %g 0 0\n',obj.tag('right',i,1),F(i));
    end
end
fprintf(fid,'}\n\n');

fprintf(fid,'#---------------------------------- Recorders ---------------------------------#\n');
fprintf(fid,'recorder Node -file {%s} -timeSeries 1 -node 0 -dof 1 accel\n',filenames.timeSeries);
fprintf(fid,'recorder Node -file {%s} -nodeRange 0 %i -dof 1 2 disp\n',filenames.disp_all,8000);
OpenSees.nodeRecorder(fid, filenames.story_disp, obj.tag('right',1:obj.nStories,1), 1, 'disp');
OpenSees.eleRecorder(fid, filenames.local_brace, obj.tag('brace',1:obj.nStories,1:obj.nBraceEle), [], 'localForce');
OpenSees.eleRecorder(fid, filenames.local_sback, obj.tag('sback',1:obj.nStories,1:obj.nBraceEle), [], 'localForce');

fprintf(fid,'file delete %s\n', filenames.nodeCoords);
fprintf(fid,'print {%s} -node\n', filenames.nodeCoords);
fprintf(fid,'record\n\n');

fprintf(fid,'#---------------------------------- Analysis ----------------------------------#\n');
fprintf(fid,'system UmfPack \n');
fprintf(fid,'constraints %s\n', obj.optionsGravityLoads.constraints.writeArgs());
fprintf(fid,'numberer RCM \n');
fprintf(fid,'analysis Static \n');

switch lower(type)
    case 'targetdrift'
        fprintf(fid,'algorithm Newton\n');
        fprintf(fid,'set ok [analyze %i]\n',ceil(targetDrift/obj.optionsPushover.stepSize));
        fprintf(fid,'if { $ok != 0 } {\n');
        fprintf(fid,'    exit 1\n');
        fprintf(fid,'}\n');
    case 'targetpostpeakratio'
        fprintf(fid,'set currentLoad [getTime]\n');
        fprintf(fid,'set maxLoad $currentLoad\n');
        fprintf(fid,'set prevNodeDisp [nodeDisp %i 1]\n',controlNode(obj));
        fprintf(fid,'while { $currentLoad >= [expr %g*$maxLoad] } {\n',targetPostPeakRatio);
        fprintf(fid,'\talgorithm %s\n',obj.optionsPushover.algorithm.type{1});
        fprintf(fid,'\ttest %s\n',obj.optionsPushover.test.writeArgs(1));
        fprintf(fid,'\tintegrator DisplacementControl %i 1 %g\n',controlNode(obj),obj.optionsPushover.stepSize(1));
        fprintf(fid,'\tset ok [analyze 1]\n');
        for iStep = 1:length(obj.optionsPushover.stepSize)
            for iTol = 1:length(obj.optionsPushover.test.tolerance)
                if iTol == 1; k = 2; else; k = 1; end
                for iAlg = k:length(obj.optionsPushover.algorithm.type)
                    fprintf(fid,'\tif { $ok != 0 } {\n');
                    fprintf(fid,'\t\talgorithm %s\n',obj.optionsPushover.algorithm.type{iAlg});
                    fprintf(fid,'\t\ttest %s\n',obj.optionsPushover.test.writeArgs(iTol));
                    fprintf(fid,'\t\tintegrator DisplacementControl %i 1 %g\n',controlNode(obj),obj.optionsPushover.stepSize(iStep));
                    fprintf(fid,'\t\tset ok [analyze 1]\n');
                    fprintf(fid,'\t}\n');
                end
            end
        end
        fprintf(fid,'\tif { $ok != 0 } {\n');
        fprintf(fid,'\t\texit 2\n');
        fprintf(fid,'\t}\n');
        fprintf(fid,'\tset currentLoad [getTime]\n');
        fprintf(fid,'\tif { $currentLoad > $maxLoad } {\n');
        fprintf(fid,'\t\tset maxLoad $currentLoad\n');
        fprintf(fid,'\t}\n');
        fprintf(fid,'\tif { [nodeDisp %i 1] > %g } {\n',controlNode(obj),obj.optionsPushover.maxDrift);
        fprintf(fid,'\t\texit 3\n');
        fprintf(fid,'\t}\n');
        fprintf(fid,'\tset curNodeDisp [nodeDisp %i 1]\n',controlNode(obj));
        fprintf(fid,'\tset dispChange [expr $curNodeDisp-$prevNodeDisp]\n');
        fprintf(fid,'\tset prevNodeDisp $curNodeDisp\n');
        fprintf(fid,'\tputs "\\nControl story displacement is now $curNodeDisp %s, a change of $dispChange %s\\n"\n',obj.units.length,obj.units.length);
        fprintf(fid,'}\n');
    otherwise
        error('Unknown analysis type: %s',type);
end

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
    case 3
        results.exitStatus = 'Peak Drift Reached';
    otherwise
        fprintf('%s\n',result);
        error('Analysis Failed in Unknown Manner (exit code: %i)',status);
end

%-------------------------------- Read Results --------------------------------%
temp = dlmread(filenames.timeSeries);
time = temp(:,1);

temp = dlmread(filenames.story_disp);
results.story_disp_x = temp;

temp = dlmread(filenames.disp_all);
results.disp_x = temp(:, 1:2:end);
results.disp_y = temp(:, 2:2:end);

coords = OpenSees.readNodeCoords(filenames.nodeCoords, 2);
results.coords_x = coords(:,1)';
results.coords_y = coords(:,2)';

temp = dlmread(filenames.local_brace);
axial               = temp(:,1:3:end);
axial(:,1:2:end)    = -axial(:,1:2:end);
results.brace_axial = axial;
shear               = temp(:,2:3:end);
shear(:,2:2:end)    = -shear(:,2:2:end);
results.brace_shear = shear;
moment              = temp(:,3:3:end);
moment(:,1:2:end)   = -moment(:,1:2:end);
results.brace_moment = moment;

temp = dlmread(filenames.local_sback);
axial               = temp(:,1:3:end);
axial(:,1:2:end)    = -axial(:,1:2:end);
results.sback_axial = axial;
shear               = temp(:,2:3:end);
shear(:,2:2:end)    = -shear(:,2:2:end);
results.sback_shear = shear;
moment              = temp(:,3:3:end);
moment(:,1:2:end)   = -moment(:,1:2:end);
results.sback_moment = moment;

%------------------------------ Computed Results ------------------------------%
storyDrift                  = results.story_disp_x;
storyDrift(:, 2:end)        = storyDrift(:, 2:end)-storyDrift(:, 1:(end-1));
results.storyDrift          = storyDrift;
results.roofDrift           = results.story_disp_x(:, end);
results.appliedStoryForce   = time*F;
results.storyShear          = cumsum(results.appliedStoryForce, 2, 'reverse');
results.baseShear           = sum(results.appliedStoryForce, 2);

% Clean Folder
if obj.deleteFilesAfterAnalysis
    fields = fieldnames(filenames);
    for i = 1:length(fields)
        delete(filenames.(fields{i}));
    end
end

function s = controlNode(obj)
    if strcmp(obj.optionsPushover.controlStory, 'roof')
        s = obj.tag('right', obj.nStories, 1);
    elseif strcmp(obj.optionsPushover.controlStory, 'brace')
        s = obj.tag('brace', 2, 4);
    else
        s = obj.tag('right', obj.optionsPushover.controlStory, 1);
    end
end

end %function:pushover
