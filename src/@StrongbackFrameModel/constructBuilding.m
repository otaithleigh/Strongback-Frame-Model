function constructBuilding(obj, fid)
%constructBuilding  Write the building model to a .tcl file

fprintf(fid, 'package require OpenSeesComposite\n');
fprintf(fid, 'model BasicBuilder -ndm 2 -ndf 3\n\n');

%% Nodes
%------------------------------------------------------------------------------%


obj.simpleNodeNumbering(fid);

%% Node masses
for iStory = 1:obj.nStories
    for jType = {'left', 'right', 'lean'}
        m = obj.nodalMass(iStory, jType{1});
        fprintf(fid, 'mass %i %g %g %g\n', obj.tag(jType{1}, iStory, 1), m, m, m);
    end
end
fprintf(fid, '\n');

%% Connections
%------------------------------------------------------------------------------%
transfTag = 1;
fprintf(fid, 'geomTransf %s %i\n', obj.transfType, transfTag);

iRigidEnd = 1;


% Ground (fixed)
for i = {'left', 'right', 'lean'}
    fprintf(fid, 'fix %4i 1 1 1\n', obj.tag(i{1}, 0, 0));
end

% Column bases
switch obj.leftColumnFixity
case 'pinned'
    fprintf(fid, 'equalDOF %4i %4i 1 2\n', obj.tag('left',0,0), obj.tag('left',0,1));
case 'fixed'
    fprintf(fid, 'equalDOF %4i %4i 1 2 3\n', obj.tag('left',0,0), obj.tag('left',0,1));
end
switch obj.rightColumnFixity
case 'pinned'
    fprintf(fid, 'equalDOF %4i %4i 1 2\n', obj.tag('right',0,0), obj.tag('right',0,1));
case 'fixed'
    fprintf(fid, 'equalDOF %4i %4i 1 2 3\n', obj.tag('right',0,0), obj.tag('right',0,1));
end
fprintf(fid, 'equalDOF %4i %4i 1 2\n', obj.tag('lean',0,0), obj.tag('lean',1,2));
fprintf(fid, '\n');

% Pinned beams at odd floors
for iStory = 1:2:obj.nStories
    rTag = obj.tag('beam', iStory, obj.beamLeftEnd(iStory));
    cTag = obj.tag('beam', iStory, obj.beamLeftEnd(iStory)+1);
    fprintf(fid, 'equalDOF %4i %4i 1 2\n', rTag, cTag);
    rTag = obj.tag('beam', iStory, obj.beamRightEnd(iStory));
    cTag = obj.tag('beam', iStory, obj.beamRightEnd(iStory)-1);
    fprintf(fid, 'equalDOF %4i %4i 1 2\n', rTag, cTag);
end

% Attach beams to columns
for iStory = 1:obj.nStories
    iTag = obj.tag('left', iStory, 1);
    jTag = obj.tag('beam', iStory, obj.beamLeftEnd(iStory));
    eleTag = obj.tag('rigidEnd', iStory, iRigidEnd);
    iRigidEnd = iRigidEnd + 1;
    fprintf(fid, 'element elasticBeamColumn %4i %4i %4i 1 %g 1 %i\n', eleTag, iTag, jTag, obj.rigidE, transfTag);

    iTag = obj.tag('right', iStory, 1);
    jTag = obj.tag('beam', iStory, obj.beamRightEnd(iStory));
    eleTag = obj.tag('rigidEnd', iStory, iRigidEnd);
    iRigidEnd = iRigidEnd + 1;
    fprintf(fid, 'element elasticBeamColumn %4i %4i %4i 1 %g 1 %i\n', eleTag, iTag, jTag, obj.rigidE, transfTag);
end

% Rigid ends in columns at even floors
for iStory = 0:2:obj.nStories
    for iType = {'left', 'right'}
        % Column above node
        if iStory ~= obj.nStories
            iTag = obj.tag(iType{1}, iStory, 1);
            jTag = obj.tag(iType{1}, iStory+1, 2);
            eleTag = obj.tag('rigidEnd', iStory, iRigidEnd);
            iRigidEnd = iRigidEnd + 1;
            fprintf(fid, 'element elasticBeamColumn %4i %4i %4i 1 %g 1 %i\n', eleTag, iTag, jTag, obj.rigidE, transfTag);
        end
        % Column below node
        if iStory ~= 0
            iTag = obj.tag(iType{1}, iStory, 1);
            jTag = obj.tag(iType{1}, iStory, 2);
            eleTag = obj.tag('rigidEnd', iStory, iRigidEnd);
            iRigidEnd = iRigidEnd + 1;
            fprintf(fid, 'element elasticBeamColumn %4i %4i %4i 1 %g 1 %i\n', eleTag, iTag, jTag, obj.rigidE, transfTag);
        end
    end
end

% Attach braces to gusset plates
for iStory = 1:obj.nStories
    switch lower(obj.GussetPlateModel)
    case 'pinned'
        for iType = {'brace', 'sback'}
            rTag = obj.tag(iType{1}, iStory, 1);
            cTag = obj.tag(iType{1}, iStory, 2);
            fprintf(fid, 'equalDOF %4i %4i 1 2\n', rTag, cTag);
            rTag = obj.tag(iType{1}, iStory, obj.nBraceNodes);
            cTag = obj.tag(iType{1}, iStory, obj.nBraceNodes-1);
            fprintf(fid, 'equalDOF %4i %4i 1 2\n', rTag, cTag);
        end
    case 'fixed'
        for iType = {'brace', 'sback'}
            rTag = obj.tag(iType{1}, iStory, 1);
            cTag = obj.tag(iType{1}, iStory, 2);
            fprintf(fid, 'equalDOF %4i %4i 1 2 3\n', rTag, cTag);
            rTag = obj.tag(iType{1}, iStory, obj.nBraceNodes);
            cTag = obj.tag(iType{1}, iStory, obj.nBraceNodes-1);
            fprintf(fid, 'equalDOF %4i %4i 1 2 3\n', rTag, cTag);
        end
    case {'elastic', 'steel01', 'steel02'}
        for iType = {'brace', 'sback'}
            if strcmp(iType{1}, 'brace')
                side = 1;
            else
                side = 2;
            end
            rTag = obj.tag(iType{1}, iStory, 1);
            cTag = obj.tag(iType{1}, iStory, 2);
            matTag = obj.tag('spring', iStory, side);
            eleTag = obj.tag('spring', iStory, side);
            Fy = obj.GussetPlates{iStory, side, 1}.Fy;
            K = obj.GussetPlates{iStory, side, 1}.K;
            switch lower(obj.GussetPlateModel)
            case 'elastic'
                fprintf(fid, 'uniaxialMaterial Elastic %i %g\n', matTag, K);
            case 'steel01'
                fprintf(fid, 'uniaxialMaterial Steel01 %i %g %g 0.01\n', matTag, Fy, K);
            case 'steel02'
                fprintf(fid, 'uniaxialMaterial Steel02 %i %g %g 0.01 20 0.925 0.15\n', matTag, Fy, K);
            end
            fprintf(fid, 'element zeroLength %i %i %i -mat %i -dir 3\n', eleTag, rTag, cTag, matTag);
            fprintf(fid, 'equalDOF %4i %4i 1 2\n', rTag, cTag);

            rTag = obj.tag(iType{1}, iStory, obj.nBraceNodes);
            cTag = obj.tag(iType{1}, iStory, obj.nBraceNodes-1);
            matTag = obj.tag('spring', iStory, side+2);
            eleTag = obj.tag('spring', iStory, side+2);
            Fy = obj.GussetPlates{iStory, side, 2}.Fy;
            K = obj.GussetPlates{iStory, side, 2}.K;
            switch lower(obj.GussetPlateModel)
            case 'elastic'
                fprintf(fid, 'uniaxialMaterial Elastic %i %g\n', matTag, K);
            case 'steel01'
                fprintf(fid, 'uniaxialMaterial Steel01 %i %g %g 0.01\n', matTag, Fy, K);
            case 'steel02'
                fprintf(fid, 'uniaxialMaterial Steel02 %i %g %g 0.01 20 0.925 0.15\n', matTag, Fy, K);
            end
            fprintf(fid, 'element zeroLength %i %i %i -mat %i -dir 3\n', eleTag, rTag, cTag, matTag);
            fprintf(fid, 'equalDOF %4i %4i 1 2\n', rTag, cTag);
        end
    end
end

% Attach corner plates to columns
for iSide = 1:2
    if iSide == 1
        col = 'left';
        brace = 'brace';
    else
        col = 'right';
        brace = 'sback';
    end
    for iStory = 1:obj.nStories
        if mod(iStory,2) ~= 0
            iTag = obj.tag(col, iStory-1, 1);
            jTag = obj.tag(brace, iStory, 1);
            eleTag = obj.tag('rigidEnd', iStory, iRigidEnd);
            iRigidEnd = iRigidEnd + 1;
            fprintf(fid, 'element elasticBeamColumn %4i %4i %4i 1 %g 1 %i\n', eleTag, iTag, jTag, obj.rigidE, transfTag);
        else
            iTag = obj.tag(col, iStory, 1);
            jTag = obj.tag(brace, iStory, obj.nBraceNodes);
            eleTag = obj.tag('rigidEnd', iStory, iRigidEnd);
            iRigidEnd = iRigidEnd + 1;
            fprintf(fid, 'element elasticBeamColumn %4i %4i %4i 1 %g 1 %i\n', eleTag, iTag, jTag, obj.rigidE, transfTag);
        end
    end
end

% Rigid zone in middle of odd story beams
for iStory = 1:2:obj.nStories
    iTag = obj.tag('beam', iStory, obj.beamLeftEnd(iStory)+2);
    jTag = obj.tag('beam', iStory, obj.beamCenterNode(iStory));
    eleTag = obj.tag('rigidEnd', iStory, iRigidEnd);
    iRigidEnd = iRigidEnd + 1;
    fprintf(fid, 'element elasticBeamColumn %4i %4i %4i 1 %g 1 %i\n', eleTag, iTag, jTag, obj.rigidE, transfTag);

    iTag = obj.tag('beam', iStory, obj.beamCenterNode(iStory));
    jTag = obj.tag('beam', iStory, obj.beamLeftEnd(iStory)+3);
    eleTag = obj.tag('rigidEnd', iStory, iRigidEnd);
    iRigidEnd = iRigidEnd + 1;
    fprintf(fid, 'element elasticBeamColumn %4i %4i %4i 1 %g 1 %i\n', eleTag, iTag, jTag, obj.rigidE, transfTag);
end

% Attach midspan plates to beams
for iType = {'brace', 'sback'}
    for iStory = 1:obj.nStories
        if mod(iStory,2) ~= 0
            iTag = obj.tag('beam', iStory, obj.beamCenterNode(iStory));
            jTag = obj.tag(iType{1}, iStory, obj.nBraceNodes);
            eleTag = obj.tag('rigidEnd', iStory, iRigidEnd);
            iRigidEnd = iRigidEnd + 1;
            fprintf(fid, 'element elasticBeamColumn %4i %4i %4i 1 %g 1 %i\n', eleTag, iTag, jTag, obj.rigidE, transfTag);
        else
            iTag = obj.tag('beam', iStory-1, obj.beamCenterNode(iStory-1));
            jTag = obj.tag(iType{1}, iStory, 1);
            eleTag = obj.tag('rigidEnd', iStory, iRigidEnd);
            iRigidEnd = iRigidEnd + 1;
            fprintf(fid, 'element elasticBeamColumn %4i %4i %4i 1 %g 1 %i\n', eleTag, iTag, jTag, obj.rigidE, transfTag);
        end
    end
end

% Attach tie braces to beams
for iStory = 2:obj.nStories-1
    rTag = obj.tag('beam', iStory-1, obj.beamCenterNode(iStory-1));
    cTag = obj.tag('tie', iStory, 1);
    fprintf(fid, 'equalDOF %4i %4i 1 2\n', rTag, cTag);
    rTag = obj.tag('beam', iStory, obj.beamCenterNode(iStory));
    cTag = obj.tag('tie', iStory, obj.nBraceEle+1);
    fprintf(fid, 'equalDOF %4i %4i 1 2\n', rTag, cTag);
end

% Tie leaning frame together
for iStory = 1:obj.nStories
    rTag = obj.tag('right', iStory, 1);
    cTag = obj.tag('lean', iStory, 1);
    fprintf(fid, 'equalDOF %i %i 1\n', rTag, cTag);
end
for iStory = 1:obj.nStories-1
    rTag = obj.tag('lean', iStory, 1);
    cTag = obj.tag('lean', iStory+1, 2);
    fprintf(fid, 'equalDOF %i %i 1 2\n', rTag, cTag);
end
fprintf(fid, '\n');

%% Sections
%------------------------------------------------------------------------------%
for iStory = 1:obj.nStories
    secTag = obj.tag('left', iStory, 1);
    matTag = obj.tag('left', iStory, 1);
    fprintf(fid, '%s\n', obj.LeftColumns{iStory}.OpenSeesSection(secTag, matTag));

    secTag = obj.tag('right', iStory, 1);
    matTag = obj.tag('right', iStory, 1);
    fprintf(fid, '%s\n', obj.RightColumns{iStory}.OpenSeesSection(secTag, matTag));

    secTag = obj.tag('beam', iStory, 1);
    matTag = obj.tag('beam', iStory, 1);
    fprintf(fid, '%s\n', obj.FrameBeams{iStory}.OpenSeesSection(secTag, matTag));

    secTag = obj.tag('brace', iStory, 1);
    matTag = obj.tag('brace', iStory, 1);
    fprintf(fid, '%s\n', obj.LeftBraces{iStory}.OpenSeesSection(secTag, matTag));

    secTag = obj.tag('sback', iStory, 1);
    matTag = obj.tag('sback', iStory, 1);
    fprintf(fid, '%s\n', obj.RightBraces{iStory}.OpenSeesSection(secTag, matTag));

    if ~isempty(obj.TieBraces{iStory})
        secTag = obj.tag('tie', iStory, 1);
        matTag = obj.tag('tie', iStory, 1);
        fprintf(fid, '%s\n', obj.TieBraces{iStory}.OpenSeesSection(secTag, matTag));
    end
end

%% Elements
%------------------------------------------------------------------------------%

% Columns
for iType = {'left', 'right'}
    for iStory = 1:obj.nStories
        secTag = obj.tag(iType{1}, iStory, 1);
        integration = sprintf('Lobatto %4i %i', secTag, obj.nIntPoints);
        for iEle = 1:obj.nColumnEle
            eleTag = obj.tag(iType{1}, iStory, iEle);
            if iEle == 1
                % First element
                if mod(iStory,2) ~= 0
                    % odd story
                    iNode = obj.tag(iType{1}, iStory, 1);
                    jNode = obj.tag(iType{1}, iStory, 3);
                else
                    % even story
                    iNode = obj.tag(iType{1}, iStory, 2);
                    jNode = obj.tag(iType{1}, iStory, 3);
                end
            elseif iEle < obj.nColumnEle
                % "Interior" elements
                num = 3 + iEle - 2;
                iNode = obj.tag(iType{1}, iStory, num);
                jNode = obj.tag(iType{1}, iStory, num+1);
            else
                iNode = obj.tag(iType{1}, iStory, obj.nColumnEle+1);
                if mod(iStory,2) ~= 0
                    jNode = obj.tag(iType{1}, iStory, 2);
                else
                    jNode = obj.tag(iType{1}, iStory-1, 1);
                end
            end
            switch obj.elementFormulation
            case 'displacement'
                fprintf(fid, 'element dispBeamColumn %4i %4i %4i %i %i %i -integration Lobatto\n',...
                    eleTag, iNode, jNode, obj.nIntPoints, secTag, transfTag);
            case 'force'
                if obj.elementIterative
                    fprintf(fid, 'element forceBeamColumn %4i %4i %4i %i "%s" -iter %i %g\n',...
                        eleTag, iNode, jNode, transfTag, integration, obj.elementIterations, obj.elementTolerance);
                else
                    fprintf(fid, 'element forceBeamColumn %4i %4i %4i %i "%s"\n',...
                        eleTag, iNode, jNode, transfTag, integration);
                end
            case 'mixed'
                fprintf(fid, 'element mixedBeamColumn2d %4i %4i %4i %i %4i %i\n',...
                    eleTag, iNode, jNode, obj.nIntPoints, secTag, transfTag);
            end
        end
    end
end

% Beams
for iStory = 1:obj.nStories
    secTag = obj.tag('beam', iStory, 1);
    integration = sprintf('Lobatto %4i %i', secTag, obj.nIntPoints);
    for iEle = 1:2*obj.nBeamEle
        eleTag = obj.tag('beam', iStory, iEle);
        if mod(iStory,2) ~= 0
            % Odd story
            iStart = obj.beamRightEnd(iStory) + 1;
            if iEle == 1
                iNode = obj.tag('beam', iStory, obj.beamLeftEnd(iStory)+1);
                jNode = obj.tag('beam', iStory, iStart);
            elseif iEle < obj.nBeamEle
                iNode = obj.tag('beam', iStory, iStart + iEle - 2);
                jNode = obj.tag('beam', iStory, iStart + iEle - 1);
            elseif iEle == obj.nBeamEle
                iNode = obj.tag('beam', iStory, iStart + obj.nBeamEle - 2);
                jNode = obj.tag('beam', iStory, obj.beamLeftEnd(iStory)+2);
            elseif iEle == obj.nBeamEle+1
                iNode = obj.tag('beam', iStory, obj.beamLeftEnd(iStory)+3);
                jNode = obj.tag('beam', iStory, iStart + obj.nBeamEle - 1);
            elseif iEle < 2*obj.nBeamEle
                iNode = obj.tag('beam', iStory, iStart + iEle - 3);
                jNode = obj.tag('beam', iStory, iStart + iEle - 2);
            else
                iNode = obj.tag('beam', iStory, obj.nBeamNodes(iStory));
                jNode = obj.tag('beam', iStory, obj.beamRightEnd(iStory)-1);
            end
        else
            % Even story
            iStart = obj.beamLeftEnd(iStory);
            if iEle == 1
                iNode = obj.tag('beam', iStory, iStart);
                jNode = obj.tag('beam', iStory, obj.beamRightEnd(iStory)+1);
            elseif iEle < obj.nBeamEle
                iNode = obj.tag('beam', iStory, iStart + iEle);
                jNode = obj.tag('beam', iStory, iStart + iEle + 1);
            elseif iEle == obj.nBeamEle
                iNode = obj.tag('beam', iStory, iStart + iEle);
                jNode = obj.tag('beam', iStory, obj.beamCenterNode(iStory));
            elseif iEle == obj.nBeamEle+1
                iNode = obj.tag('beam', iStory, obj.beamCenterNode(iStory));
                jNode = obj.tag('beam', iStory, iStart + iEle);
            elseif iEle < 2*obj.nBeamEle
                iNode = obj.tag('beam', iStory, iStart + iEle - 1);
                jNode = obj.tag('beam', iStory, iStart + iEle);
            else
                iNode = obj.tag('beam', iStory, obj.nBeamNodes(iStory));
                jNode = obj.tag('beam', iStory, obj.beamRightEnd(iStory));
            end
        end
        switch obj.elementFormulation
        case 'displacement'
            fprintf(fid, 'element dispBeamColumn %4i %4i %4i %i %i %i -integration Lobatto\n',...
                eleTag, iNode, jNode, obj.nIntPoints, secTag, transfTag);
        case 'force'
            if obj.elementIterative
                fprintf(fid, 'element forceBeamColumn %4i %4i %4i %i "%s" -iter %i %g\n',...
                    eleTag, iNode, jNode, transfTag, integration, obj.elementIterations, obj.elementTolerance);
            else
                fprintf(fid, 'element forceBeamColumn %4i %4i %4i %i "%s"\n',...
                    eleTag, iNode, jNode, transfTag, integration);
            end
        case 'mixed'
            fprintf(fid, 'element mixedBeamColumn2d %4i %4i %4i %i %4i %i\n',...
                eleTag, iNode, jNode, obj.nIntPoints, secTag, transfTag);
        end
    end
end

% Braces
for iType = {'brace', 'sback'}
    for iStory = 1:obj.nStories
        iStart = 2;
        secTag = obj.tag(iType{1}, iStory, 1);
        integration = sprintf('Lobatto %4i %i', secTag, obj.nIntPoints);
        for iEle = 1:obj.nBraceEle
            eleTag = obj.tag(iType{1}, iStory, iEle);
            iNode = obj.tag(iType{1}, iStory, iStart + iEle - 1);
            jNode = obj.tag(iType{1}, iStory, iStart + iEle);
            switch obj.elementFormulation
            case 'displacement'
                fprintf(fid, 'element dispBeamColumn %4i %4i %4i %i %i %i -integration Lobatto\n',...
                    eleTag, iNode, jNode, obj.nIntPoints, secTag, transfTag);
            case 'force'
                if obj.elementIterative
                    fprintf(fid, 'element forceBeamColumn %4i %4i %4i %i "%s" -iter %i %g\n',...
                        eleTag, iNode, jNode, transfTag, integration, obj.elementIterations, obj.elementTolerance);
                else
                    fprintf(fid, 'element forceBeamColumn %4i %4i %4i %i "%s"\n',...
                        eleTag, iNode, jNode, transfTag, integration);
                end
            case 'mixed'
                fprintf(fid, 'element mixedBeamColumn2d %4i %4i %4i %i %4i %i\n',...
                    eleTag, iNode, jNode, obj.nIntPoints, secTag, transfTag);
            end
        end
    end
end

% Ties
for iStory = 1:obj.nStories
    if ~isempty(obj.TieBraces{iStory})
        secTag = obj.tag('tie', iStory, 1);
        integration = sprintf('Lobatto %4i %i', secTag, obj.nIntPoints);
        for iEle = 1:obj.nBraceEle
            eleTag = obj.tag('tie', iStory, iEle);
            iNode = obj.tag('tie', iStory, iEle);
            jNode = obj.tag('tie', iStory, iEle+1);
            switch obj.elementFormulation
            case 'displacement'
                fprintf(fid, 'element dispBeamColumn %4i %4i %4i %i %i %i -integration Lobatto\n',...
                    eleTag, iNode, jNode, obj.nIntPoints, secTag, transfTag);
            case 'force'
                if obj.elementIterative
                    fprintf(fid, 'element forceBeamColumn %4i %4i %4i %i "%s" -iter %i %g\n',...
                        eleTag, iNode, jNode, transfTag, integration, obj.elementIterations, obj.elementTolerance);
                else
                    fprintf(fid, 'element forceBeamColumn %4i %4i %4i %i "%s"\n',...
                        eleTag, iNode, jNode, transfTag, integration);
                end
            case 'mixed'
                fprintf(fid, 'element mixedBeamColumn2d %4i %4i %4i %i %4i %i\n',...
                    eleTag, iNode, jNode, obj.nIntPoints, secTag, transfTag);
            end
        end
    end
end

% Leaning columns
for iStory = 1:obj.nStories
    eleTag = obj.tag('lean', iStory, 1);
    iTag = obj.tag('lean', iStory, 1);
    jTag = obj.tag('lean', iStory, 2);
    fprintf(fid, 'element elasticBeamColumn %4i %4i %4i 1 %g 1 %i\n', eleTag, iTag, jTag, obj.rigidE, transfTag);
end


% function end: 'constructBuilding'
end
