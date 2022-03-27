AddCSLuaFile()

DEFINE_BASECLASS "weapon_tttbase"

sound.Add( {
	name = "earrapeblast",
	channel = CHAN_WEAPON,
	volume = 2.0,
	level = 140,
	pitch = {95, 110},
	sound = "shotgun_earrape.wav"
} )


if CLIENT then
    SWEP.PrintName = "Earrape Shotgun"
    SWEP.Slot = 1.0
    SWEP.Icon = "vgui/ttt/earrape/earrape_icon"
end

SWEP.Base = "weapon_tttbase"
SWEP.HoldType = "shotgun"

SWEP.EquipMenuData = {
   type = "really fucking powerful shotgun",
   desc = "Loud. Louder. Earrape Shotgun \n Decimate your fellow terrorists with this body mincer. 1-time-use"
};


SWEP.Primary.Ammo = "Buckshot"
SWEP.AmmoEnt = "None"
SWEP.Primary.Delay = 0.01
SWEP.Primary.Recoil = 0.01
SWEP.Primary.Cone = 0.30
SWEP.Primary.Damage = 35
SWEP.Primary.Automatic = true
SWEP.Primary.ClipSize = 8
SWEP.Primary.ClipMax = 8
SWEP.Primary.DefaultClip = 8
SWEP.Primary.Sound = Sound("earrapeblast")
SWEP.Primary.NumShots = 31
SWEP.Primary.Force = 5000

SWEP.UseHands = true
SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 58
--SWEP.ViewModel                  = "models/weapons/v_sawedoff.mdl"  --old models wothount .phy-files
--SWEP.WorldModel                 = "models/weapons/w_sawedoff.mdl"
SWEP.ViewModel			= Model("models/weapons/v_doublebarrl.mdl")
SWEP.WorldModel			= Model("models/weapons/w_double_barrel_shotgun.mdl")

SWEP.IronSightsPos = Vector(-7.67, -12.86, 3.371)
SWEP.IronSightsAng = Vector(0.637, 0.01, -1.458)

SWEP.Kind = WEAPON_HEAVY
SWEP.AutoSpawnable = false
SWEP.InLoadoutFor = {nil}
SWEP.CanBuy = { ROLE_TRAITOR }
SWEP.AllowDrop = true
SWEP.IsSilent = false
SWEP.NoSights = false
 
function SWEP:SetupDataTables()
   self:DTVar("Bool", 0, "reloading")
 
   return self.BaseClass.SetupDataTables(self)
end

function SWEP:Reload()
self:SetIronsights( false )

--if self.Weapon:GetNetworkedBool( "reloading", false ) then return end
if self.dt.reloading then return end

if not IsFirstTimePredicted() then return end

if self.Weapon:Clip1() < self.Primary.ClipSize and self.Owner:GetAmmoCount( self.Primary.Ammo ) > 0 then
  
   if self:StartReload() then
      return
   end
end

end

function SWEP:StartReload()
--if self.Weapon:GetNWBool( "reloading", false ) then
if self.dt.reloading then
   return false
end

if not IsFirstTimePredicted() then return false end

self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
self.Weapon:EmitSound("weapons/sawedoff/sawedoff_reload.wav")

local ply = self.Owner

if not ply or ply:GetAmmoCount(self.Primary.Ammo) <= 0 then
   return false
end

local wep = self.Weapon

if wep:Clip1() >= self.Primary.ClipSize then
   return false
end

wep:SendWeaponAnim(ACT_SHOTGUN_RELOAD_START)

self.reloadtimer =  CurTime() + wep:SequenceDuration()

--wep:SetNWBool("reloading", true)
self.dt.reloading = true

return true
end

function SWEP:PerformReload()
local ply = self.Owner

-- prevent normal shooting in between reloads
self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )

if not ply or ply:GetAmmoCount(self.Primary.Ammo) <= 0 then return end

local wep = self.Weapon

if wep:Clip1() >= self.Primary.ClipSize then return end

self.Owner:RemoveAmmo( 1, self.Primary.Ammo, false )
self.Weapon:SetClip1( self.Weapon:Clip1() + 1 )

wep:SendWeaponAnim(ACT_VM_RELOAD)

self.reloadtimer = CurTime() + wep:SequenceDuration()
end

function SWEP:FinishReload()
self.dt.reloading = false
self.Weapon:SendWeaponAnim(ACT_SHOTGUN_RELOAD_FINISH)

self.reloadtimer = CurTime() + self.Weapon:SequenceDuration()
end

function SWEP:CanPrimaryAttack()
    if self.Weapon:Clip1() <= 0 then
       --elf:EmitSound( "Weapon_Shotgun.Empty" )
       self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
       return false
    end
    return true
 end
  
 function SWEP:Think()
    if self.dt.reloading and IsFirstTimePredicted() then
       if self.Owner:KeyDown(IN_ATTACK) then
          self:FinishReload()
          return
       end
      
       if self.reloadtimer <= CurTime() then
  
          if self.Owner:GetAmmoCount(self.Primary.Ammo) <= 0 then
             self:FinishReload()
          elseif self.Weapon:Clip1() < self.Primary.ClipSize then
             self:PerformReload()
          else
             self:FinishReload()
          end
          return            
       end
    end
 end
  
 function SWEP:Deploy()
    self.dt.reloading = false
    self.reloadtimer = 0
    return self.BaseClass.Deploy(self)
 end
 
 --using this to precache the important stuff
 function SWEP:Precache()
      util.PrecacheSound("earrapeblast")
   end 

-- The shotgun's headshot damage multiplier is based on distance. The closer it
-- is, the more damage it does. This reinforces the shotgun's role as short
-- range weapon by reducing effectiveness at mid-range, where one could score
-- lucky headshots relatively easily due to the spread.
function SWEP:GetHeadshotMultiplier(victim, dmginfo)
    local att = dmginfo:GetAttacker()
    if not IsValid(att) then return 3 end
    
    local dist = victim:GetPos():Distance(att:GetPos())
    local d = math.max(0, dist - 140)
    
    -- Decay from 3.1 to 1 slowly as distance increases
    return 1 + math.max(0, (2.1 - 0.002 * (d ^ 1.25)))
end

function SWEP:SecondaryAttack()
    if self.NoSights or (not self.IronSightsPos) or self:GetReloading() then return end
    -- if self:GetNextSecondaryFire() > CurTime() then return end
    
    self:SetIronsights(not self:GetIronsights())
    
    self:SetNextSecondaryFire(CurTime() + 0.3)
end
