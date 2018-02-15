function simpleNodeNumbering(obj, fid)
%simpleNodeNumbering
%

% Ground nodes -----------------------------------------------------------------
fprintf(fid, 'node %4i 0 0\n',  obj.tag('left', 0, 0));
fprintf(fid, 'node %4i %g 0\n', obj.tag('right', 0, 0), obj.bayWidth);
fprintf(fid, 'node %4i 0 0\n',  obj.tag('left', 0, 1));
fprintf(fid, 'node %4i %g 0\n', obj.tag('right', 0, 1), obj.bayWidth);
fprintf(fid, 'node %4i %g 0\n', obj.tag('lean', 0, 0), 2*obj.bayWidth);
fprintf(fid, '\n');

floorBelowHeight = [0, cumsum(obj.storyHeight(1:obj.nStories-1))];

for iStory = 1:obj.nStories

    % Left side columns --------------------------------------------------------
    x = 0;
    y = floorBelowHeight(iStory) + obj.storyHeight(iStory);
    tag = obj.tag('left', iStory, 1);
    fprintf(fid, 'node %4i %g %g\n', tag, x, y);

    % Nodes for rigid end zones
    if mod(iStory,2) ~= 0
        % On odd floors, plates are at the bottom of the column
        if iStory == 1
            rigidEndLength = obj.GussetPlates{iStory, 1, 1}.b;
        else
            rigidEndLength = obj.FrameBeams{iStory-1}.shape.d/2 + obj.GussetPlates{iStory, 1, 1}.b;
        end
        y = floorBelowHeight(iStory) + rigidEndLength;
    else
        % On even floors, plates are at the top of the column
        rigidEndLength = obj.FrameBeams{iStory}.shape.d/2 + obj.GussetPlates{iStory, 1, 2}.b;
        y = floorBelowHeight(iStory) + obj.storyHeight(iStory) - rigidEndLength;
    end
    tag = obj.tag('left', iStory, 2);
    fprintf(fid, 'node %4i %g %g\n', tag, x, y);

    % Nodes for nonlinearity
    if obj.nColumnEle > 1
        yDiff = (obj.storyHeight(iStory) - rigidEndLength)/obj.nColumnEle;
        for iNode = 1:(obj.nColumnEle - 1)
            if mod(iStory,2) ~= 0
                y = floorBelowHeight(iStory) + obj.storyHeight(iStory) - iNode*yDiff;
            else
                y = floorBelowHeight(iStory) + obj.storyHeight(iStory) - rigidEndLength - iNode*yDiff;
            end
            tag = obj.tag('left', iStory, 2+iNode);
            fprintf(fid, 'node %4i %g %g\n', tag, x, y);
        end
    end

    % Right side columns -------------------------------------------------------
    x = obj.bayWidth;
    y = floorBelowHeight(iStory) + obj.storyHeight(iStory);
    tag = obj.tag('right', iStory, 1);
    fprintf(fid, 'node %4i %g %g\n', tag, x, y);

    % Nodes for rigid end zones
    if mod(iStory,2) ~= 0
        % On odd floors, plates are at the bottom of the column
        if iStory == 1
            rigidEndLength = obj.GussetPlates{iStory, 2, 1}.b;
        else
            rigidEndLength = obj.FrameBeams{iStory-1}.shape.d/2 + obj.GussetPlates{iStory, 2, 1}.b;
        end
        y = floorBelowHeight(iStory) + rigidEndLength;
    else
        % On even floors, plates are at the top of the column
        rigidEndLength = obj.FrameBeams{iStory}.shape.d/2 + obj.GussetPlates{iStory, 2, 2}.b;
        y = floorBelowHeight(iStory) + obj.storyHeight(iStory) - rigidEndLength;
    end
    tag = obj.tag('right', iStory, 2);
    fprintf(fid, 'node %4i %g %g\n', tag, x, y);

    % Nodes for nonlinearity
    if obj.nColumnEle > 1
        yDiff = (obj.storyHeight(iStory) - rigidEndLength)/obj.nColumnEle;
        for iNode = 1:(obj.nColumnEle - 1)
            if mod(iStory,2) ~= 0
                y = floorBelowHeight(iStory) + obj.storyHeight(iStory) - iNode*yDiff;
            else
                y = floorBelowHeight(iStory) + obj.storyHeight(iStory) - rigidEndLength - iNode*yDiff;
            end
            tag = obj.tag('right', iStory, 2+iNode);
            fprintf(fid, 'node %4i %g %g\n', tag, x, y);
        end
    end

    % Leaning columns ----------------------------------------------------------
    x = 2*obj.bayWidth;
    y = floorBelowHeight(iStory) + obj.storyHeight(iStory);
    tag = obj.tag('lean', iStory, 1);
    fprintf(fid, 'node %4i %g %g\n', tag, x, y);
    y = floorBelowHeight(iStory);
    tag = obj.tag('lean', iStory, 2);
    fprintf(fid, 'node %4i %g %g\n', tag, x, y);


    % Beams --------------------------------------------------------------------
    x = [];
    y = [];
    x(1) = obj.bracePos*obj.bayWidth;
    for iSide = 1:2
        if iStory == obj.nStories
            plateAbove = struct;
            plateAbove.a = 0;
            plateAbove.dc = 0;
        else
            plateAbove = obj.GussetPlates{iStory+1,iSide,1};
        end
        plateBelow = obj.GussetPlates{iStory,iSide,2};
        if iSide == 1
            % Left side
            if mod(iStory,2) ~= 0
                % Odd story
                rigidLeftLength = obj.LeftColumns{iStory}.shape.d/2;
                rigidRightLength = 0.75*max(plateBelow.a,plateAbove.a) + plateAbove.dc/2;
                x(2) = rigidLeftLength;
                x(3) = x(2);
                x(4) = obj.bracePos*obj.bayWidth - rigidRightLength;
            else
                % Even story
                rigidLeftLength = 0.75*max(plateBelow.a,plateAbove.a) + plateAbove.dc/2;
                rigidRightLength = 0;
                x(2) = rigidLeftLength;
            end

            xDiff = (obj.bracePos*obj.bayWidth - rigidLeftLength - rigidRightLength)/obj.nBeamEle;
            for iNode = 1:(obj.nBeamEle-1)
                st = obj.nBeamNodes(iStory) - 2*(obj.nBeamEle-1);
                x(st + iNode) = rigidLeftLength + iNode*xDiff;
            end
        else
            % Right side
            if mod(iStory,2) ~= 0
                % Odd story
                rigidLeftLength = 0.75*max(plateBelow.a,plateAbove.a) + plateAbove.dc/2;
                rigidRightLength = obj.RightColumns{iStory}.shape.d/2;
                x(5) = obj.bracePos*obj.bayWidth + rigidLeftLength;
                x(6) = obj.bayWidth - rigidRightLength;
                x(7) = x(6);
            else
                % Even story
                rigidLeftLength = 0;
                rigidRightLength = 0.75*max(plateBelow.a,plateAbove.a) + plateAbove.dc/2;
                x(3) = obj.bayWidth - rigidRightLength;
            end

            xDiff = ((1-obj.bracePos)*obj.bayWidth - rigidLeftLength - rigidRightLength)/obj.nBeamEle;
            for iNode = 1:(obj.nBeamEle-1)
                st = obj.nBeamNodes(iStory) - (obj.nBeamEle-1);
                x(st + iNode) = obj.bracePos*obj.bayWidth + rigidLeftLength + iNode*xDiff;
            end
        end
    end

    y = floorBelowHeight(iStory) + obj.storyHeight(iStory);
    for iNum = 1:obj.nBeamNodes(iStory)
        tag = obj.tag('beam', iStory, iNum);
        fprintf(fid, 'node %4i %g %g\n', tag, x(iNum), y);
    end

    % Left braces --------------------------------------------------------------
    plateBelow = obj.GussetPlates{iStory, 1, 1};
    plateAbove = obj.GussetPlates{iStory, 1, 2};
    rigidBelowLength = plateBelow.L4 + plateBelow.L2;
    rigidAboveLength = plateAbove.L4 + plateBelow.L2;
    L = obj.storyHeight(iStory) * cscd(plateBelow.alpha) - rigidBelowLength - rigidAboveLength;

    % Plop out x and y coordinates on a line, then rotate to correct position.
    x_brace_coord = rigidBelowLength + linspace(0, L, obj.nBraceEle+1);
    y_brace_coord = obj.imperf * L * sin(pi*(x_brace_coord-rigidBelowLength)/L);

    if mod(iStory,2) ~= 0
        % Odd story
        R = [cosd(plateBelow.alpha), -sind(plateBelow.alpha)
             sind(plateBelow.alpha),  cosd(plateBelow.alpha)];
    else
        % Even story
        R = [cosd(180-plateBelow.alpha), -sind(180-plateBelow.alpha)
             sind(180-plateBelow.alpha),  cosd(180-plateBelow.alpha)];
    end

    rot = R*[x_brace_coord;y_brace_coord];
    x = [rot(1,1), rot(1,:), rot(1,end)];
    y = [rot(2,1), rot(2,:), rot(2,end)];

    if mod(iStory,2) ~= 0
        % Odd story
        % x = x
    else
        % Even story
        x = x + obj.bracePos*obj.bayWidth;
    end

    y = y + floorBelowHeight(iStory);

    for iNode = 1:obj.nBraceNodes
        tag = obj.tag('brace', iStory, iNode);
        fprintf(fid, 'node %4i %g %g\n', tag, x(iNode), y(iNode));
    end


    % Right braces -------------------------------------------------------------
    plateBelow = obj.GussetPlates{iStory, 2, 1};
    plateAbove = obj.GussetPlates{iStory, 2, 2};
    rigidBelowLength = plateBelow.L4 + plateBelow.L2;
    rigidAboveLength = plateAbove.L4 + plateBelow.L2;
    L = obj.storyHeight(iStory) * cscd(plateBelow.alpha) - rigidBelowLength - rigidAboveLength;

    % Plop out x and y coordinates on a line, then rotate to correct position.
    x_brace_coord = rigidBelowLength + linspace(0, L, obj.nBraceEle+1);
    y_brace_coord = obj.imperf * L * sin(pi*(x_brace_coord-rigidBelowLength)/L);

    if mod(iStory,2) ~= 0
        % Odd story
        R = [cosd(180-plateBelow.alpha), -sind(180-plateBelow.alpha)
             sind(180-plateBelow.alpha),  cosd(180-plateBelow.alpha)];
    else
        % Even story
        R = [cosd(plateBelow.alpha), -sind(plateBelow.alpha)
             sind(plateBelow.alpha),  cosd(plateBelow.alpha)];
    end

    rot = R*[x_brace_coord;y_brace_coord];
    x = [rot(1,1), rot(1,:), rot(1,end)];
    y = [rot(2,1), rot(2,:), rot(2,end)];

    if mod(iStory,2) ~= 0
        % Odd story
        x = x + obj.bayWidth;
    else
        % Even story
        x = x + obj.bracePos*obj.bayWidth;
    end

    y = y + floorBelowHeight(iStory);

    for iNode = 1:obj.nBraceNodes
        tag = obj.tag('sback', iStory, iNode);
        fprintf(fid, 'node %4i %g %g\n', tag, x(iNode), y(iNode));
    end

    % Tie braces ---------------------------------------------------------------
    % for now, stick them to the beams
    if ~isempty(obj.TieBraces{iStory})
        x = obj.bracePos*obj.bayWidth;
        for iNode = 1:obj.nBraceEle+1
            y = floorBelowHeight(iStory) + (iNode-1)/obj.nBraceEle * obj.storyHeight(iStory);
            tag = obj.tag('tie', iStory, iNode);
            fprintf(fid, 'node %4i %g %g\n', tag, x, y);
        end
    end


end
