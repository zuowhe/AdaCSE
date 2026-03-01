function key = generate_hash_key(j, ps)
% GENERATE_HASH_KEY 为 (j, ps) 生成唯一数值键

    if isempty(ps)
        ps = [];
    else
        ps = unique(ps(:))';
        ps = sort(ps);
    end

    key = uint64(j);
    mult = uint64(31);

    for i = 1:length(ps)
        key = key * mult + uint64(ps(i));
    end

    % 转为 double 以兼容 containers.Map
    key = double(key);

end