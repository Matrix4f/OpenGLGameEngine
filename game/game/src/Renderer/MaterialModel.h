#pragma once
#include <vector>
#include <memory>
#include <glm/vec3.hpp>

#include "ResourceMgr/TextureResource.h"
#include "VertexArray.h"
#include "IndexBuffer.h"
#include "Mesh.h"

struct MaterialModelProperties
{
	
	TextureResource* specularMap;
	bool fullyRender;
	float shineDistanceDamper, reflectivity;

	MaterialModelProperties()
		: specularMap(nullptr), fullyRender(false), shineDistanceDamper(0), reflectivity(0)
	{
	}

	inline bool operator==(const MaterialModelProperties& other) const
	{
		return specularMap == other.specularMap && fullyRender == other.fullyRender
			&& shineDistanceDamper == other.shineDistanceDamper
			&& reflectivity == other.reflectivity;
	}

	inline bool hasSpecularMap() const
	{
		return specularMap != nullptr;
	}

	inline bool operator!=(const MaterialModelProperties& other) const
	{
		return !operator==(other);
	}
};

template<>
struct std::hash<MaterialModelProperties>
{
	size_t operator()(const MaterialModelProperties& obj)
	{
		size_t i = std::hash<bool>()(obj.fullyRender) ^
			std::hash<float>()(obj.shineDistanceDamper) ^
			std::hash<float>()(obj.reflectivity) ^
			std::hash<bool>()(obj.hasSpecularMap());
		if (obj.hasSpecularMap())
			i ^= std::hash<std::string>()(obj.specularMap->getFilepath());
		return i;
	}
};

class MaterialModel
{
private:
	TextureResource & texture;
	GlModel model;
	
	std::string objName;
	
public:
	MaterialModelProperties properties;

public:
	MaterialModel(TextureResource& texture, const GlModel& model, const std::string& name);

	inline void useSpecularMap(TextureResource& specularMap)
	{
		properties.specularMap = &specularMap;
	}
	inline bool doesHaveSpecularMap() const { return properties.hasSpecularMap(); }
	inline TextureResource& getSpecularMap() { return *properties.specularMap; }
	inline const TextureResource& getSpecularMap() const { return *properties.specularMap; }

	inline const GlModel& getGlModel() const { return model; }
	inline TextureResource& getTexture() { return texture; }
	inline const TextureResource& getTexture() const { return texture; }
	inline const std::string& getObjName() const { return objName; }

	inline bool operator==(const MaterialModel& model) const
	{
		if (model.objName != objName ||
			model.texture.getFilepath() != texture.getFilepath() ||
			model.doesHaveSpecularMap() != doesHaveSpecularMap() ||
			model.properties != properties)
			return false;

		if (model.doesHaveSpecularMap() && model.properties.specularMap->promisedFetch().getID() != properties.specularMap->promisedFetch().getID())
			return false;

		return true;
	}
};

template<>
struct std::hash<MaterialModel>
{
	std::size_t operator()(const MaterialModel& model) const
	{
		std::size_t h = std::hash<std::string>()(model.getObjName()) ^
			std::hash<std::string>()(model.getTexture().getFilepath()) ^
			std::hash<MaterialModelProperties>()(model.properties);
			
		return h;
	}
};