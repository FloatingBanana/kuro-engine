local Utils = {}

function Utils.AABB(x1,y1,w1,h1, x2,y2,w2,h2)
	return x1 < x2+w2 and
		   x2 < x1+w1 and
		   y1 < y2+h2 and
		   y2 < y1+h1
end

function Utils.vecAABB(pos1, size1, pos2, size2)
	return Utils.AABB(pos1.x, pos1.y, size1.x, size1.y, pos2.x, pos2.y, size2.x, size2.y)
end

return Utils