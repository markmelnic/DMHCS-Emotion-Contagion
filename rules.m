function [ fncs ] = rules()
    % DO NOT EDIT
    fncs = l2.getRules();
    for i=1:length(fncs)
        fncs{i} = str2func(fncs{i});
    end
end

%ADD RULES BELOW

function result = ddr1( trace, params, t )
    result = {};

    %go through each expressiveness
    for has_expressiveness = trace(t).has_expressiveness
        agent = has_expressiveness.arg{1}; %agent name
        expressiveness = has_expressiveness.arg{2}; %the expressiveness

        %go through each channel strength to find influenced agents
        for has_channel_strength = l2.getall(trace, t, 'has_channel_strength',{agent, NaN, NaN})
            agent2 = has_channel_strength.arg{2}; %agent name of the other agent
            channel_strength = has_channel_strength.arg{3}; %channel strength

            %get the openness of that agent
            has_openness = l2.getall(trace, t, 'has_openness', {agent2, NaN});
                openness = has_openness.arg{2}; %the openness

            %calculate the contagion strength
            contagion_strength = expressiveness * channel_strength * openness;

            %add the result
            result = { result{:} ...
                {t+1, 'has_contagion_strength', {agent, agent2, contagion_strength}}};
        end
    end
end

function result = ddr2 (trace, params, t)

	result = {};

	%get emotion level of agent A
	for has_emotion_level = trace(t).has_emotion_level
		agent = has_emotion_level.arg{1}; %agent name
		emotion_level = has_emotion_level.arg{2}; %emotion level

		%initialize variable to calculate emotion change
		emotion_change = 0;

		%go through each contagion strength affecting this agent
		for has_contagion_strength = l2.getall(trace, t, 'has_contagion_strength', {NaN, agent, NaN})
			agent2 = has_contagion_strength.arg{1}; %name of the other agent
			contagion_strength = has_contagion_strength.arg{3}; %contagion strength

			%get the emotion level of that agent
			[~, has_emotion_level_b] = l2.exists(trace, t, 'has_emotion_level', {agent2, NaN});
			emotion_level_b = has_emotion_level_b.arg{2}; %the emotion level of the other agent
            
            %calculate and update emotion change
            emotion_change = emotion_change + contagion_strength * (emotion_level_b - emotion_level) * params.step_size;
        end

        %set the new emotion level
        emotion_level = emotion_level + emotion_change;

        %add the new emotion level to the results
        result = {result{:} {t+1, 'has_emotion_level', {agent, emotion_level}}};
    end
end

function result = ddr3 (trace, params, t)

	result = {};

	%get emotion level of agent A
	for has_emotion_level = trace(t).has_emotion_level
		agent = has_emotion_level.arg{1}; %agent name
		emotion_level = has_emotion_level.arg{2}; %emotion level

        if emotion_level <= params.emotion_state1
            result = {result{:} {t+1, 'has_emotion_state', {agent, 'angry'}}};
        elseif (emotion_level > params.emotion_state1) && (emotion_level < params.emotion_state2)
            result = {result{:} {t+1, 'has_emotion_state', {agent, 'sad'}}};
        elseif (emotion_level > params.emotion_state2) && (emotion_level < params.emotion_state3)
            result = {result{:} {t+1, 'has_emotion_state', {agent, 'indifferent'}}};
        elseif emotion_level > params.emotion_state3
            result = {result{:} {t+1, 'has_emotion_state', {agent, 'happy'}}};
        end
    end
end
