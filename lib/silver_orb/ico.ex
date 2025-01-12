defmodule SilverOrb.ICO do
  use Orb

  Memory.pages(2)

  defwp write_header(write_ptr: I32.UnsafePointer, count: I32), I32.UnsafePointer do
    Memory.store!(I32.U16, write_ptr, 0)
    Memory.store!(I32.U16, write_ptr + 2, 1)
    Memory.store!(I32.U16, write_ptr + 4, count)
    write_ptr + 6
  end

  defwp write_image_directory(
          write_ptr: I32.UnsafePointer,
          width: I32,
          height: I32,
          image_offset: I32
        ),
        I32.UnsafePointer do
    Memory.store!(I32.U8, write_ptr, width)
    Memory.store!(I32.U8, write_ptr + 1, height)
    Memory.store!(I32.U8, write_ptr + 2, 0)
    Memory.store!(I32.U8, write_ptr + 3, 0)
    Memory.store!(I32.U16, write_ptr + 4, 1)
    Memory.store!(I32.U16, write_ptr + 6, 32)
    Memory.store!(I32, write_ptr + 8, width * height * 4 + 40)
    Memory.store!(I32, write_ptr + 12, image_offset)
    write_ptr + 16
  end

  defwp write_image_data(write_ptr: I32.UnsafePointer, width: I32, height: I32, r: I32.U8, g: I32.U8, b: I32.U8),
    y: I32,
    x: I32 do
    Memory.store!(I32, write_ptr, 40)
    Memory.store!(I32, write_ptr + 4, width)
    Memory.store!(I32, write_ptr + 8, height * 2)
    Memory.store!(I32.U16, write_ptr + 12, 1)
    Memory.store!(I32.U16, write_ptr + 14, 32)
    Memory.store!(I32, write_ptr + 16, 0)
    Memory.store!(I32, write_ptr + 20, width * height)
    Memory.store!(I32, write_ptr + 24, 0)
    Memory.store!(I32, write_ptr + 28, 0)
    Memory.store!(I32, write_ptr + 32, 0)
    Memory.store!(I32, write_ptr + 36, 0)

    write_ptr = write_ptr + 40

    loop Rows do
      x = 0

      loop Columns do
        # Memory.store!(I32, write_ptr + ((height - y - 1) * width + x) * 4, color)
        Memory.store!(I32.U8, write_ptr + ((height - y - 1) * width + x) * 4 + 0, b)
        Memory.store!(I32.U8, write_ptr + ((height - y - 1) * width + x) * 4 + 1, g)
        Memory.store!(I32.U8, write_ptr + ((height - y - 1) * width + x) * 4 + 2, r)
        Memory.store!(I32.U8, write_ptr + ((height - y - 1) * width + x) * 4 + 3, 0xFF)

        x = x + 1

        if x < width do
          Columns.continue()
        end
      end

      y = y + 1

      if y < height do
        Rows.continue()
      end
    end
  end

  defw write(write_ptr: I32.UnsafePointer, width: I32, height: I32, r: I32.U8, g: I32.U8, b: I32.U8), I32 do
    write_ptr = write_header(write_ptr, 1)
    write_ptr = write_image_directory(write_ptr, width, height, 6 + 16)
    # write_image_data(write_ptr, width, height, I32.wrap_i64(color))
    write_image_data(write_ptr, width, height, r, g, b)
    6 + 16 + 40 + width * height * 4
  end
end
