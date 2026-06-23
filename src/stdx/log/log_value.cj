/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.log

import std.collection.{HashMap, TreeMap}
import std.time.DateTime

public interface LogValue {
    func writeTo(w: LogWriter): Unit
}

func writeLogObject<V>(w: LogWriter, values: Iterable<(String, V)>): Unit where V <: LogValue {
    w.startObject()
    for ((k, v) in values) {
        w.writeKey(k)
        w.writeValue(v)
    }
    w.endObject()
}

extend Int64 <: LogValue {
    public func writeTo(w: LogWriter): Unit {
        w.writeInt(this)
    }
}

extend Bool <: LogValue {
    public func writeTo(w: LogWriter): Unit {
        w.writeBool(this)
    }
}

extend Float64 <: LogValue {
    public func writeTo(w: LogWriter): Unit {
        w.writeFloat(this)
    }
}

extend DateTime <: LogValue {
    public func writeTo(w: LogWriter): Unit {
        w.writeDateTime(this)
    }
}

extend Duration <: LogValue {
    public func writeTo(w: LogWriter): Unit {
        w.writeDuration(this)
    }
}

extend String <: LogValue {
    public func writeTo(w: LogWriter): Unit {
        w.writeString(this)
    }
}

extend Exception <: LogValue {
    public func writeTo(w: LogWriter): Unit {
        w.writeException(this)
    }
}

extend<T> Array<T> <: LogValue where T <: LogValue {
    public func writeTo(w: LogWriter): Unit {
        w.startArray()
        for (e in this) {
            w.writeValue(e)
        }
        w.endArray()
    }
}

extend<V> HashMap<String, V> <: LogValue where V <: LogValue {
    public func writeTo(w: LogWriter): Unit {
        writeLogObject(w, this)
    }
}

extend<V> TreeMap<String, V> <: LogValue where V <: LogValue {
    public func writeTo(w: LogWriter): Unit {
        writeLogObject(w, this)
    }
}

extend<T> Option<T> <: LogValue where T <: LogValue {
    public func writeTo(w: LogWriter): Unit {
        if (let Some(v) <- this) {
            w.writeValue(v)
        } else {
            w.writeNone()
        }
    }
}
