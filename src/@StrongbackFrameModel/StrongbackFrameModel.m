classdef StrongbackFrameModel < OpenSeesAnalysis
%StrongbackFrameModel  OpenSees frame-level model of strongback.

properties
% General properties -----------------------------------------------------------

g               % Acceleration due to gravity
units           % Units of the model: force, length, time

% Geometric properties (global) ------------------------------------------------

nStories        % Number of stories
storyHeight     % Vector of floor heights
nBays           % Number of bays in each direction
bayWidth        % Width of each bay
nJoists         % Number of gravity-load-carrying joists per bay

bracePos = 0.5  % Position of brace intersection with beams, as a ratio of bay width
nBraceEle       % Number of elements per brace
nColumnEle      % Number of elements per column
nBeamEle        % Number of elements per beam (from column to brace)
imperf          % Ratio of length used for initial brace imperfections

% Frame loading ----------------------------------------------------------------

deadLoad        % Vector of total distributed dead loads per floor
liveLoad        % Vector of total distributed live loads per floor

% Section properties -----------------------------------------------------------
% The following should be cell vectors of `FrameMember`s.

LeftColumns     % Columns on the left side of the frame
RightColumns    % Columns on the right side of the frame
FrameBeams      % Beam sections
LeftBraces      % Diagonal braces
RightBraces     % Diagonal braces in the strongback
TieBraces       % Vertical ties in the strongback

GussetPlates
GussetPlateModel = 'pinned'

elasticLinearBraces = false;
elasticLinearBeams  = false;
elasticLinearCols   = false;

% Material properties ----------------------------------------------------------

ColumnMat = SteelDesign.SteelMaterial('A992')
BeamMat   = SteelDesign.SteelMaterial('A992')
BraceMat  = SteelDesign.SteelMaterial('A500 Gr. C')
PlateMat  = SteelDesign.SteelMaterial('A572 Gr. 50', 'Plate')

rigidE = 10e12; % Elastic modulus used for "rigid" beam-columns

% Analysis options -------------------------------------------------------------

optionsGravityLoads = OpenSees.GravityLoadOptions
optionsPushover     = OpenSees.PushoverOptions
optionsResponseHistory = OpenSees.ResponseHistoryOptions

% Geometric transformation used for analysis: Linear, PDelta, or Corotational
transfType {mustBeMember(transfType, {'Linear', 'PDelta', 'Corotational'})} = 'PDelta'

nIntPoints = 5                          % Number of integration points per element
nFibers = 20
includeExplicitPDelta = true            % Select whether to include gravity loads on the frame
includeGeometricImperfections = false   % Select whether to include geometric imperfections (braces only)
includeResidualStresses = true          % Select whether to include residual stresses (W-sections only)
residualStressFactor = 0.3              % Maximum compressive residual stress factor
nResidualStressSectors = 10

end


properties (Dependent) %--------------------------------------------------------
    braceAngle      % Undeflected angle of brace with level below, deg
    braceLength     % Undeflected length of brace
    braceImperf     % Initial imperfection perpendicular to brace at brace midspan
    braceImperf_X   % X-component of initial brace imperfection
    braceImperf_Y   % Y-component of initial brace imperfection

    nBraceNodes     % Number of nodes that comprise a brace

end

methods
%##############################################################################%

function obj = StrongbackFrameModel()
%StrongbackFrameModel  Constructor
end

function braceAngle = get.braceAngle(obj)
    braceAngle = atand(obj.storyHeight / (obj.bracePos*obj.bayWidth));
end

function braceLength = get.braceLength(obj)
    braceLength = obj.bayWidth * secd(obj.braceAngle);
end

function braceImperf = get.braceImperf(obj)
    braceImperf = obj.imperf * obj.braceLength;
end

function braceImperf_X = get.braceImperf_X(obj)
    braceImperf_X = obj.braceImperf * sind(obj.braceAngle);
end

function braceImperf_Y = get.braceImperf_Y(obj)
    braceImperf_Y = obj.braceImperf * cosd(obj.braceAngle);
end

function nBraceNodes = get.nBraceNodes(obj)
    nBraceNodes = obj.nBraceEle + 3;
end

function n = nBeamNodes(obj,story)
    if mod(story,2) == 0
        n = 3 + 2*(obj.nBeamEle-1);
    else
        n = 7 + 2*(obj.nBeamEle-1);
    end
end


end %methods


methods (Static)
%==============================================================================%
function t = beamCenterNode(story)
    if mod(story,2) == 0
        t = 1;
    else
        t = 1;
    end
end

function t = beamLeftEnd(story)
    if mod(story,2) == 0
        t = 2;
    else
        t = 2;
    end
end

function t = beamRightEnd(story)
    if mod(story,2) == 0
        t = 3;
    else
        t = 7;
    end
end

function t = tag(kind, story, num)
%tag  Retrieve the appropriate OpenSees tag
%
%   t = tag(kind, story, num)
%
    switch lower(kind)
    case 'left'
        start = 0;
    case 'right'
        start = 1;
    case 'lean'
        start = 2;
    case 'beam'
        start = 3;
    case 'brace'
        start = 4;
    case 'sback'
        start = 5;
    case 'tie'
        start = 6;
    case 'rigidend'
        start = 7;
    case 'spring'
        start = 8;
    otherwise
        error('Invalid node type: %s', kind)
    end

    t = 1000*start + 100*story + num;
end

end %methods (Static)

end %classdef
