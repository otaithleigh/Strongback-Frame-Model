% StrongbackFrameTest.m
% Tester script for the StrongbackFrameModel
%
% Units: kip, in, sec

clear('frame', 'pushover', 'rh')

import SteelDesign.*

frame = StrongbackFrameModel;

frame.seismicDesignCategory = 'Dmax';
frame.respModCoeff = 6;
frame.impFactor    = 1;

frame.g             = 386;      % in./s^2
frame.units.force   = 'kip';
frame.units.length  = 'in.';
frame.units.time    = 'sec';

frame.nStories      = 4;                    % Number of stories
frame.storyHeight   = [12, 12, 12, 12]*12;  % Story heights (ft --> in.)
frame.nBays         = 3;                    % Number of bays
frame.bayWidth      = 24*12;                % Width of bays (ft --> in.)
frame.bracePos      = 0.5;                  % Position along beam where braces connect
frame.nJoists       = 2;                    % Number of joists per bay

frame.deadLoad      = [ 60, 60, 60, 10 ]/(144*1000);   % psf --> ksi
frame.liveLoad      = [ 0, 0, 0, 0 ];

% From spreadsheet; some values div by two b/c two frames per loading direction
ELF = struct;
ELF.seismicResponseCoefficient = 0.1667;
ELF.baseShear       = 164.16/2;
ELF.storyForce      = [24.14, 49.07, 74.32, 16.63]/2;
ELF.storyShear      = cumsum(ELF.storyForce, 'reverse');
ELF.allowableDrift  = 0.020*frame.storyHeight;

%% Analysis options
%------------------------------------------------------------------------------%
% General
frame.echoOpenSeesOutput        = true;
frame.deleteFilesAfterAnalysis  = false;

% Elements
frame.transfType = 'Corotational';  % Geometric transformation for all elements
frame.nIntPoints = 3;               % Number of integration points per element
frame.nFibers    = 20;              % Number of fibers per section
frame.nBraceEle  = 8;               % Number of elements per brace member
frame.nColumnEle = 8;               % Number of elements per column member
frame.nBeamEle   = 4;               % Number of elements per half-beam member
frame.imperf     = 1/1000;

frame.elementFormulation = 'mixed';
frame.elementIterative   = false;
frame.elementTolerance   = 1e-12;
frame.elementIterations  = 10;

frame.leftColumnFixity  = 'pinned';
frame.rightColumnFixity = 'pinned';

% Materials
frame.rigidE                    = 10e9;     % Elastic modulus of "rigid" elements
frame.includeResidualStresses   = true;     % Select whether to include residual stresses in material models
frame.nResidualStressSectors    = 20;
frame.GussetPlateModel          = 'Steel01'; % Select how to model gusset plate connections

frame.elasticLinearBraces = false;
frame.elasticLinearBeams  = false;
frame.elasticLinearCols   = false;

% Pushover
a = 2.5/100;
frame.optionsPushover.stepSize          = [a, a/5, a/10, a/50, a/100];
frame.optionsPushover.maxDrift          = 24; % in.
frame.optionsPushover.controlStory      = 'roof';
frame.optionsPushover.test.tolerance    = [1e-5, 1e-4, 1e-3];
frame.optionsPushover.test.iterations   = 30;
frame.optionsPushover.test.print        = 2;
frame.optionsPushover.algorithm.type    = {'KrylovNewton', 'SecantNewton', 'BFGS', 'ModifiedNewton'};

% Response history
gm_mat = '/home/petertalley/Dropbox/Research/Strongback-Frame-Model/test/ground_motions.mat';
gmIndex = 1;
SF = 1.3;

frame.optionsResponseHistory.test.tolerance  = [1e-5, 1e-4, 1e-3];
frame.optionsResponseHistory.test.iterations = 20;
frame.optionsResponseHistory.algorithm.type  = {'KrylovNewton', 'SecantNewton', 'BFGS', 'ModifiedNewton'};


%% Section definitions
%------------------------------------------------------------------------------%
t = SteelSection.readShapesTable('US');

frame.LeftColumns = {
    FrameMember(frame, SteelSection('W14x82', 'US', t), 1, 'column')
    FrameMember(frame, SteelSection('W14x82', 'US', t), 2, 'column')
    FrameMember(frame, SteelSection('W14x61', 'US', t), 3, 'column')
    FrameMember(frame, SteelSection('W14x61', 'US', t), 4, 'column')
};

frame.RightColumns = {
    FrameMember(frame, SteelSection('W14x82', 'US', t), 1, 'column')
    FrameMember(frame, SteelSection('W14x82', 'US', t), 2, 'column')
    FrameMember(frame, SteelSection('W14x61', 'US', t), 3, 'column')
    FrameMember(frame, SteelSection('W14x61', 'US', t), 4, 'column')
};

frame.FrameBeams = {
    FrameMember(frame, SteelSection('W27x178', 'US', t), 1, 'beam')
    FrameMember(frame, SteelSection('W27x178', 'US', t), 2, 'beam')
    FrameMember(frame, SteelSection('W27x217', 'US', t), 3, 'beam')
    FrameMember(frame, SteelSection('W14x68', 'US', t), 4, 'beam')
};

frame.LeftBraces = {
    FrameMember(frame, SteelSection('HSS4-1/2x4-1/2x5/16', 'US', t), 1, 'brace')
    FrameMember(frame, SteelSection('HSS4x4x3/8', 'US', t), 2, 'brace')
    FrameMember(frame, SteelSection('HSS3-1/2x3-1/2x3/8', 'US', t), 3, 'brace')
    FrameMember(frame, SteelSection('HSS3x3x1/4', 'US', t), 4, 'brace')
};

frame.TieBraces = {
    ''
    FrameMember(frame, SteelSection('HSS6x6x3/8', 'US', t), 2, 'tie')
    FrameMember(frame, SteelSection('HSS5x5x5/16', 'US', t), 3, 'tie')
    ''
};

frame.RightBraces = {
    FrameMember(frame, SteelSection('HSS6x6x3/8', 'US', t), 1, 'sback')
    FrameMember(frame, SteelSection('HSS6x6x3/8', 'US', t), 2, 'sback')
    FrameMember(frame, SteelSection('HSS5x5x3/8', 'US', t), 3, 'sback')
    FrameMember(frame, SteelSection('HSS4x4x5/16', 'US', t), 4, 'sback')
};

frame.designGussetPlates();


%% Do stuff
%------------------------------------------------------------------------------%

% ELF = frame.equivalentLateralForceAnalysis();

% Pushover
% tic
% F = frame.pushoverForceDistribution();
% pushover = frame.pushover(F, 'targetPostPeakRatio', 0.80);
% pushover.runTime = toc;
% fprintf('Pushover took %g seconds\n', pushover.runTime)
% fprintf('%s at a roof drift of %g in.\n\n', pushover.exitStatus, pushover.roofDrift(end))
%
% pushover = frame.processPushover(pushover, ELF);
%
% frame.plotPushoverCurve(pushover)
% hold on
% plot(xlim, [ELF.baseShear, ELF.baseShear], 'k--')
% plot([0 pushover.roofDrift(end)], [pushover.peak80Shear, pushover.peak80Shear], 'r-')
% plot([pushover.roofDrift(end), pushover.roofDrift(end)], [0 pushover.peak80Shear], 'r-')
%
% frame.plotPushoverDrifts(pushover)
% frame.plotStoryDrifts(pushover, 'singleplot')

% Response history
load( gm_mat, 'ground_motions' );

% parfor gmIndex = [1, 3, 5, 7]
% tic
gmID   = ground_motions(gmIndex).ID;
gmFile = scratchFile(frame,sprintf('acc%s.acc',gmID));
dt     = ground_motions(gmIndex).dt;
tEnd   = ground_motions(gmIndex).time(end) + 5;
accel  = ground_motions(gmIndex).normalized_acceleration;
dlmwrite(gmFile,accel*frame.g);

SF = [1.5, 2];
rh = cell(1,length(SF));
parfor i=1:length(SF)
    tic
    rh{i} = frame.responseHistory(gmFile, dt, SF(i), tEnd, gmID, i);
    rh{i}.runTime = toc;
    fprintf('Response history took %g seconds\n', rh{i}.runTime)
    fprintf('%s at %g seconds into the time series\n\n', rh{i}.exitStatus, rh{i}.time(end))
end
for i=1:length(SF)
    energy = frame.energyCriterion(rh{i});
    figure
    hold on
    plot(rh{i}.time, energy.earthquake)
    plot(rh{i}.time, energy.norm_gravity)
    xlabel('Time (s)')
    ylabel('Energy (kip*in)')
    title(sprintf('Scale factor = %g', SF(i)))
end

% end
%
% figure
% plot(rh.time, rh.roofDrift);
% xlabel('Time (s)')
% ylabel('Roof drift (in.)')
% yl = ylim;
% ylim([-max(abs(yl)), max(abs(yl))])
% grid on
%
% figure
% plot(rh.time, rh.baseShear);
% xlabel('Time (s)')
% ylabel('Base shear (kip)')
% yl = ylim;
% ylim([-max(abs(yl)), max(abs(yl))])
% grid on
%
% figure
% hold on
% plot(rh{i}.time, rh{i}.storyDrift ./ frame.storyHeight * 100);
% legend('Story 1', 'Story 2', 'Story 3', 'Story 4')
% xlabel('Time (s)')
% ylabel('Story drift ratio (%)')
% yl = ylim;
% ylim([-max(abs(yl)), max(abs(yl))])
% grid on
