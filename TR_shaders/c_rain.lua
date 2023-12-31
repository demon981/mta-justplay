RainShader = {}
RainShader.__index = RainShader

function RainShader:create()
	local instance = {}
	setmetatable(instance, RainShader)
	if instance:constructor() then
		return instance
	end
	return false
end

function RainShader:constructor()
	self.shader = dxCreateShader("files/shaders/replace.fx")

	self.texture = dxCreateTexture("files/images/transparent.png")

	if not self.shader or not self.texture then
		exports.TR_noti:create("Nie udało się uruchomić shadera. Prawdopodobnie twoja karta graficzna nie wspiera tego rodzaju modelu shaderów, lub nie masz zainstalowanych najnowszych sterowników.", "error", 10)
		self:destroy()
		return
    end

    dxSetShaderValue(self.shader, "gTexture", self.texture)
    engineApplyShaderToWorldTexture(self.shader, "bullethitsmoke")

	return true
end

function RainShader:destroy()
	if isElement(self.shader) then
		engineRemoveShaderFromWorldTexture(self.shader, "bullethitsmoke")
		destroyElement(self.shader)
	end
	if isElement(self.texture) then destroyElement(self.texture) end

	self = nil
end