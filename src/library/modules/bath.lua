local fun = {
	sign = function(number)
		return number > 0 and 1 or (number == 0 and 0 or -1)
	end
}
return fun
