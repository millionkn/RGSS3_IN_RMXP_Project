# Header: psdk.pokemonworkshop.com/index.php/ScriptHeader
# Author: Nuri Yuri
# Date: 2017
# Update: 2017-09-08
# ScriptNorm: No
# Description: Affichage des tiles sur la map
class Tilemap
	attr_accessor :tileset, :autotiles, :map_data, :priorities, :ox, :oy
  attr_reader :viewport, :disposed
  
  Autotile_Frame_Count = 15
  Autotiles = [
    [ [27, 28, 33, 34], [ 5, 28, 33, 34], [27,  6, 33, 34], [ 5,  6, 33, 34],
      [27, 28, 33, 12], [ 5, 28, 33, 12], [27,  6, 33, 12], [ 5,  6, 33, 12] ],
    [ [27, 28, 11, 34], [ 5, 28, 11, 34], [27,  6, 11, 34], [ 5,  6, 11, 34],
      [27, 28, 11, 12], [ 5, 28, 11, 12], [27,  6, 11, 12], [ 5,  6, 11, 12] ],
    [ [25, 26, 31, 32], [25,  6, 31, 32], [25, 26, 31, 12], [25,  6, 31, 12],
      [15, 16, 21, 22], [15, 16, 21, 12], [15, 16, 11, 22], [15, 16, 11, 12] ],
    [ [29, 30, 35, 36], [29, 30, 11, 36], [ 5, 30, 35, 36], [ 5, 30, 11, 36],
      [39, 40, 45, 46], [ 5, 40, 45, 46], [39,  6, 45, 46], [ 5,  6, 45, 46] ],
    [ [25, 30, 31, 36], [15, 16, 45, 46], [13, 14, 19, 20], [13, 14, 19, 12],
      [17, 18, 23, 24], [17, 18, 11, 24], [41, 42, 47, 48], [ 5, 42, 47, 48] ],
    [ [37, 38, 43, 44], [37,  6, 43, 44], [13, 18, 19, 24], [13, 14, 43, 44],
      [37, 42, 43, 48], [17, 18, 47, 48], [13, 18, 43, 48], [ 1,  2,  7,  8] ]
  ]
  SRC = Rect.new(0, 0, 16, 16)
  #> Nombre de sprites pour les positions x et positions y
  NX = 22
  NY = 17
  #> De cache (pour des optimisations de transition)
  @@autotile_bmp = Array.new(384)
  @@autotiles_copy = Array.new(7, -1)
  @@autotile_db = Hash.new
  
  def initialize(viewport)
    @viewport = viewport
    @autotiles = Array.new(7)
    @autotiles_counter = Array.new(8, 0)
    @autotiles_copy = @@autotiles_copy
    @autotiles_bmp = @@autotile_bmp
    make_sprites(viewport)
    check_copy(@autotiles_copy)
    @last_ox = @last_oy = nil #> Prévenir d'un déplacement inutile
    @disposed = false
  end
  
  # ox / 32 = position du premier tile visible, oy / 32 pareil
  def update
    return if @disposed
    ox = @ox
    oy = @oy
    #> S'il y a une variation dans les autotiles
    if @autotiles != @autotiles_copy
      remake_autotiles
      draw_all(@last_x = ox / 32 - 1, @last_y = oy / 32 - 1, ox % 32, oy % 32)
    #> Si le compteur tombe sur le moment de mise à jour des autotiles
    elsif (Graphics.frame_count % Autotile_Frame_Count) == 0
      x = ox / 32 - 1
      y = oy / 32 - 1
      #> Si la position a changée il faut remettre les bitmaps où il faut
      if(x != @last_x or y != @last_y)
        draw_all(@last_x = x, @last_y = y, ox % 32, oy % 32)
      else
        draw_autotiles(@last_x = x, @last_y = y, ox % 32, oy % 32)
      end
    #> Si la map a bougée
    elsif ox != @last_ox or oy != @last_oy
      x = ox / 32 - 1
      y = oy / 32 - 1
      #> Si la position a changée il faut remettre les bitmaps où il faut
      if(x != @last_x or y != @last_y)
        draw_all(@last_x = x, @last_y = y, ox % 32, oy % 32)
      else
        update_positions(@last_x = x, @last_y = y, ox % 32, oy % 32)
      end
    end
    @last_ox = ox
    @last_oy = oy
  end
  
  #===
  #> Fonction de dessin des autotiles
  #  Cette fonction ajuste les compteur d'autorile et réactualise les src_rect
  #===
  def draw_autotiles(x, y, ox, oy)
    map_data = @map_data
    autotiles_counter = @autotiles_counter
    autotiles_bmp = @autotiles_bmp
    1.upto(7) do |index|
      counter = autotiles_counter[index]
      counter += 32
      counter = 0 if(autotiles_bmp[index * 48].height <= counter)
      autotiles_counter[index] = counter
    end
    @sprites.each_with_index do |sprite_table, pz|
      sprite_table.each_with_index do |sprite_col, px|
        sprite_col.each_with_index do |sprite, py|
          sprite.ox = ox
          sprite.oy = oy
          tile_id = map_data[x + px, y + py, pz]
          if(tile_id and tile_id > 0 and tile_id < 384) #Autotile
            sprite.src_rect.set(0, autotiles_counter[tile_id / 48], 32, 32)
          end
        end
      end
    end
  end
  #===
  #> Fonction de dessin de tous les sprites
  #  Cette fonction ajuste le bitmap du sprite ainsi que son src_rect, elle recalcule aussi la position z
  #  Formule simplifiée du z : sprite.y + priority * 32 + 32 ou 0 si priority == 0
  #  Supprimer add_z pour avoir une priorité plus haute des tiles
  #===
  def draw_all(x, y, ox, oy)
    priorities = @priorities
    map_data = @map_data
    autotiles_counter = @autotiles_counter
    autotiles_bmp = @autotiles_bmp
    tileset = @tileset
    add_z = oy / 2
    @sprites.each_with_index do |sprite_table, pz|
      sprite_table.each_with_index do |sprite_col, px|
        sprite_col.each_with_index do |sprite, py|
          sprite.ox = ox
          sprite.oy = oy
          tile_id = map_data[x + px, y + py, pz]
          if(!tile_id or tile_id <= 0)
            next(sprite.bitmap = nil)
          elsif(tile_id < 384) #Autotile
            sprite.bitmap = autotiles_bmp[tile_id]
            sprite.src_rect.set(0, autotiles_counter[tile_id / 48], 32, 32)
          else #Tile
            tid = tile_id - 384
            sprite.bitmap = tileset
            sprite.src_rect.set(tid % 8 * 32, tid / 8 * 32, 32, 32)
          end
          priority = priorities[tile_id]
          next(sprite.z = 0) if !priority or priority == 0
          sprite.z = (py + priority) * 32 - add_z
        end
      end
    end
    
  end
  
  #===
  #> Fonction de mise à jour des positions
  #  Cette fonction actualise la position ox/oy des sprites + Petite opti pour les bâtiments
  #  La méthode contient ce qui est commenté en temps normal (priorité plus haute des tiles)
  #===
  def update_positions(x, y, ox, oy)
    priorities = @priorities
    map_data = @map_data
    add_z = oy / 2
    @sprites.each_with_index do |sprite_table, pz|
      sprite_table.each_with_index do |sprite_col, px|
        sprite_col.each_with_index do |sprite, py|
          sprite.ox = ox
          sprite.oy = oy
          tile_id = map_data[x + px, y + py, pz]
          next if(!tile_id or tile_id <= 0)
          priority = priorities[tile_id]
          next if !priority or priority == 0
          sprite.z = (py + priority) * 32 - add_z
        end
      end
    end
=begin
    @sprites.each do |sprite_table|
      sprite_table.each do |sprite_col|
        sprite_col.each do |sprite|
          sprite.ox = ox
          sprite.oy = oy
        end
      end
    end
=end
  end
  
  def dispose
    return if @disposed
    @sprites.each { |sprite_array| sprite_array.each { |sprite_col| sprite_col.each { |sprite| sprite.dispose } } }
    @disposed = true
  end
  alias disposed? disposed
  
  def make_sprites(viewport, tile_size = 32, zoom = 1)
    sprite = nil
    @sprites = Array.new(3) do
      Array.new(NX) do |x|
        Array.new(NY) do |y|
          sprite = Sprite.new(viewport)
          sprite.x = (x - 1) * tile_size
          sprite.y = (y - 1) * tile_size
          sprite.zoom_x = sprite.zoom_y = zoom
          next(sprite)
        end
      end
    end
  end
  
  def remake_autotiles
    autotiles = @autotiles
    autotiles_copy = @autotiles_copy
    7.times do |j|
      if autotiles_copy[j] != autotiles[j]
        autotiles_copy[j] = autotiles[j]
        load_autotile(j, (j + 1) * 48, autotiles)
      end
    end
  end
  
  def check_copy(copy)
    7.times do |i|
      if copy[i] and copy[i] != -1
        if copy[i].disposed?
          @@autotiles_copy = @autotiles_copy = Array.new(7, -1)
        end
        break
      end
    end
  end
  
  def load_autotile(j, base_id, autotiles)
    autotile_name = $game_map.autotile_names[j]
    autotiles_bmp = @autotiles_bmp
    if(autotile_data = @@autotile_db[autotile_name])
      unless autotile_data.first.disposed?
        autotile_data.each_with_index do |autotile, i|
          autotiles_bmp[base_id + i] = autotile
        end
        return
      end
    end
    autotile_data = []
    base_id.upto(base_id + 47) do |i|
      autotile_data << (autotiles_bmp[i] = generate_autotile_bmp(i, autotiles))
    end
    @@autotile_db[autotile_name] = autotile_data
  end
  
  def generate_autotile_bmp(id, autotiles)
    autotile = autotiles[id / 48 - 1]
    return Bitmap.new(32, 32) if !autotile or autotile.width < 96
    src = SRC
    id %= 48
    tiles = Autotiles[id>>3][id&7]
    frames = autotile.width / 96
    bmp = Bitmap.new(32, frames * 32)
    frames.times do |x|
      anim = x * 96
      4.times do |i|
        tile_position = tiles[i] - 1
        src.set(tile_position % 6 * 16 + anim, tile_position / 6 * 16, 16, 16)
        bmp.blt(i % 2 * 16, i / 2 * 16 + x * 32, autotile, src)
      end
    end
    return bmp
  end
end

class Yuri_Tilemap < Tilemap
  def make_sprites(viewport)
    super(viewport, 16, 0.5)
  end
end