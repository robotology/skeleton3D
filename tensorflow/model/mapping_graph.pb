node {
  name: "input_producer/Const"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
          dim {
            size: 1
          }
        }
        string_val: "../matlab/inMatrix_balanced.csv"
      }
    }
  }
}
node {
  name: "input_producer/Size"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 1
      }
    }
  }
}
node {
  name: "input_producer/Greater/y"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 0
      }
    }
  }
}
node {
  name: "input_producer/Greater"
  op: "Greater"
  input: "input_producer/Size"
  input: "input_producer/Greater/y"
  attr {
    key: "T"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "input_producer/Assert/Const"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "string_input_producer requires a non-null input tensor"
      }
    }
  }
}
node {
  name: "input_producer/Assert/Assert/data_0"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "string_input_producer requires a non-null input tensor"
      }
    }
  }
}
node {
  name: "input_producer/Assert/Assert"
  op: "Assert"
  input: "input_producer/Greater"
  input: "input_producer/Assert/Assert/data_0"
  attr {
    key: "T"
    value {
      list {
        type: DT_STRING
      }
    }
  }
  attr {
    key: "summarize"
    value {
      i: 3
    }
  }
}
node {
  name: "input_producer/Identity"
  op: "Identity"
  input: "input_producer/Const"
  input: "^input_producer/Assert/Assert"
  attr {
    key: "T"
    value {
      type: DT_STRING
    }
  }
}
node {
  name: "input_producer/RandomShuffle"
  op: "RandomShuffle"
  input: "input_producer/Identity"
  attr {
    key: "T"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "seed"
    value {
      i: 0
    }
  }
  attr {
    key: "seed2"
    value {
      i: 0
    }
  }
}
node {
  name: "input_producer"
  op: "FIFOQueueV2"
  attr {
    key: "capacity"
    value {
      i: 32
    }
  }
  attr {
    key: "component_types"
    value {
      list {
        type: DT_STRING
      }
    }
  }
  attr {
    key: "container"
    value {
      s: ""
    }
  }
  attr {
    key: "shapes"
    value {
      list {
        shape {
        }
      }
    }
  }
  attr {
    key: "shared_name"
    value {
      s: ""
    }
  }
}
node {
  name: "input_producer/input_producer_EnqueueMany"
  op: "QueueEnqueueManyV2"
  input: "input_producer"
  input: "input_producer/RandomShuffle"
  attr {
    key: "Tcomponents"
    value {
      list {
        type: DT_STRING
      }
    }
  }
  attr {
    key: "timeout_ms"
    value {
      i: -1
    }
  }
}
node {
  name: "input_producer/input_producer_Close"
  op: "QueueCloseV2"
  input: "input_producer"
  attr {
    key: "cancel_pending_enqueues"
    value {
      b: false
    }
  }
}
node {
  name: "input_producer/input_producer_Close_1"
  op: "QueueCloseV2"
  input: "input_producer"
  attr {
    key: "cancel_pending_enqueues"
    value {
      b: true
    }
  }
}
node {
  name: "input_producer/input_producer_Size"
  op: "QueueSizeV2"
  input: "input_producer"
}
node {
  name: "input_producer/Cast"
  op: "Cast"
  input: "input_producer/input_producer_Size"
  attr {
    key: "DstT"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "SrcT"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "input_producer/mul/y"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
        }
        float_val: 0.03125
      }
    }
  }
}
node {
  name: "input_producer/mul"
  op: "Mul"
  input: "input_producer/Cast"
  input: "input_producer/mul/y"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "input_producer/fraction_of_32_full/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "input_producer/fraction_of_32_full"
      }
    }
  }
}
node {
  name: "input_producer/fraction_of_32_full"
  op: "ScalarSummary"
  input: "input_producer/fraction_of_32_full/tags"
  input: "input_producer/mul"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "input_producer_1/Const"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
          dim {
            size: 1
          }
        }
        string_val: "../matlab/refMatrix_balanced.csv"
      }
    }
  }
}
node {
  name: "input_producer_1/Size"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 1
      }
    }
  }
}
node {
  name: "input_producer_1/Greater/y"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 0
      }
    }
  }
}
node {
  name: "input_producer_1/Greater"
  op: "Greater"
  input: "input_producer_1/Size"
  input: "input_producer_1/Greater/y"
  attr {
    key: "T"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "input_producer_1/Assert/Const"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "string_input_producer requires a non-null input tensor"
      }
    }
  }
}
node {
  name: "input_producer_1/Assert/Assert/data_0"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "string_input_producer requires a non-null input tensor"
      }
    }
  }
}
node {
  name: "input_producer_1/Assert/Assert"
  op: "Assert"
  input: "input_producer_1/Greater"
  input: "input_producer_1/Assert/Assert/data_0"
  attr {
    key: "T"
    value {
      list {
        type: DT_STRING
      }
    }
  }
  attr {
    key: "summarize"
    value {
      i: 3
    }
  }
}
node {
  name: "input_producer_1/Identity"
  op: "Identity"
  input: "input_producer_1/Const"
  input: "^input_producer_1/Assert/Assert"
  attr {
    key: "T"
    value {
      type: DT_STRING
    }
  }
}
node {
  name: "input_producer_1/RandomShuffle"
  op: "RandomShuffle"
  input: "input_producer_1/Identity"
  attr {
    key: "T"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "seed"
    value {
      i: 0
    }
  }
  attr {
    key: "seed2"
    value {
      i: 0
    }
  }
}
node {
  name: "input_producer_1"
  op: "FIFOQueueV2"
  attr {
    key: "capacity"
    value {
      i: 32
    }
  }
  attr {
    key: "component_types"
    value {
      list {
        type: DT_STRING
      }
    }
  }
  attr {
    key: "container"
    value {
      s: ""
    }
  }
  attr {
    key: "shapes"
    value {
      list {
        shape {
        }
      }
    }
  }
  attr {
    key: "shared_name"
    value {
      s: ""
    }
  }
}
node {
  name: "input_producer_1/input_producer_1_EnqueueMany"
  op: "QueueEnqueueManyV2"
  input: "input_producer_1"
  input: "input_producer_1/RandomShuffle"
  attr {
    key: "Tcomponents"
    value {
      list {
        type: DT_STRING
      }
    }
  }
  attr {
    key: "timeout_ms"
    value {
      i: -1
    }
  }
}
node {
  name: "input_producer_1/input_producer_1_Close"
  op: "QueueCloseV2"
  input: "input_producer_1"
  attr {
    key: "cancel_pending_enqueues"
    value {
      b: false
    }
  }
}
node {
  name: "input_producer_1/input_producer_1_Close_1"
  op: "QueueCloseV2"
  input: "input_producer_1"
  attr {
    key: "cancel_pending_enqueues"
    value {
      b: true
    }
  }
}
node {
  name: "input_producer_1/input_producer_1_Size"
  op: "QueueSizeV2"
  input: "input_producer_1"
}
node {
  name: "input_producer_1/Cast"
  op: "Cast"
  input: "input_producer_1/input_producer_1_Size"
  attr {
    key: "DstT"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "SrcT"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "input_producer_1/mul/y"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
        }
        float_val: 0.03125
      }
    }
  }
}
node {
  name: "input_producer_1/mul"
  op: "Mul"
  input: "input_producer_1/Cast"
  input: "input_producer_1/mul/y"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "input_producer_1/fraction_of_32_full/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "input_producer_1/fraction_of_32_full"
      }
    }
  }
}
node {
  name: "input_producer_1/fraction_of_32_full"
  op: "ScalarSummary"
  input: "input_producer_1/fraction_of_32_full/tags"
  input: "input_producer_1/mul"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "TextLineReaderV2"
  op: "TextLineReaderV2"
  attr {
    key: "container"
    value {
      s: ""
    }
  }
  attr {
    key: "shared_name"
    value {
      s: ""
    }
  }
  attr {
    key: "skip_header_lines"
    value {
      i: 0
    }
  }
}
node {
  name: "TextLineReaderV2_1"
  op: "TextLineReaderV2"
  attr {
    key: "container"
    value {
      s: ""
    }
  }
  attr {
    key: "shared_name"
    value {
      s: ""
    }
  }
  attr {
    key: "skip_header_lines"
    value {
      i: 0
    }
  }
}
node {
  name: "ReaderReadV2"
  op: "ReaderReadV2"
  input: "TextLineReaderV2"
  input: "input_producer"
}
node {
  name: "ReaderReadV2_1"
  op: "ReaderReadV2"
  input: "TextLineReaderV2_1"
  input: "input_producer_1"
}
node {
  name: "DecodeCSV/record_defaults_0"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
          dim {
            size: 1
          }
        }
        float_val: 1.0
      }
    }
  }
}
node {
  name: "DecodeCSV/record_defaults_1"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
          dim {
            size: 1
          }
        }
        float_val: 1.0
      }
    }
  }
}
node {
  name: "DecodeCSV/record_defaults_2"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
          dim {
            size: 1
          }
        }
        float_val: 1.0
      }
    }
  }
}
node {
  name: "DecodeCSV/record_defaults_3"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
          dim {
            size: 1
          }
        }
        float_val: 1.0
      }
    }
  }
}
node {
  name: "DecodeCSV/record_defaults_4"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
          dim {
            size: 1
          }
        }
        float_val: 1.0
      }
    }
  }
}
node {
  name: "DecodeCSV/record_defaults_5"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
          dim {
            size: 1
          }
        }
        float_val: 1.0
      }
    }
  }
}
node {
  name: "DecodeCSV"
  op: "DecodeCSV"
  input: "ReaderReadV2:1"
  input: "DecodeCSV/record_defaults_0"
  input: "DecodeCSV/record_defaults_1"
  input: "DecodeCSV/record_defaults_2"
  input: "DecodeCSV/record_defaults_3"
  input: "DecodeCSV/record_defaults_4"
  input: "DecodeCSV/record_defaults_5"
  attr {
    key: "OUT_TYPE"
    value {
      list {
        type: DT_FLOAT
        type: DT_FLOAT
        type: DT_FLOAT
        type: DT_FLOAT
        type: DT_FLOAT
        type: DT_FLOAT
      }
    }
  }
  attr {
    key: "field_delim"
    value {
      s: ","
    }
  }
}
node {
  name: "input_features"
  op: "Pack"
  input: "DecodeCSV"
  input: "DecodeCSV:1"
  input: "DecodeCSV:2"
  input: "DecodeCSV:3"
  input: "DecodeCSV:4"
  input: "DecodeCSV:5"
  attr {
    key: "N"
    value {
      i: 6
    }
  }
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "axis"
    value {
      i: 0
    }
  }
}
node {
  name: "DecodeCSV_1/record_defaults_0"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
          dim {
            size: 1
          }
        }
        float_val: 1.0
      }
    }
  }
}
node {
  name: "DecodeCSV_1/record_defaults_1"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
          dim {
            size: 1
          }
        }
        float_val: 1.0
      }
    }
  }
}
node {
  name: "DecodeCSV_1/record_defaults_2"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
          dim {
            size: 1
          }
        }
        float_val: 1.0
      }
    }
  }
}
node {
  name: "DecodeCSV_1"
  op: "DecodeCSV"
  input: "ReaderReadV2_1:1"
  input: "DecodeCSV_1/record_defaults_0"
  input: "DecodeCSV_1/record_defaults_1"
  input: "DecodeCSV_1/record_defaults_2"
  attr {
    key: "OUT_TYPE"
    value {
      list {
        type: DT_FLOAT
        type: DT_FLOAT
        type: DT_FLOAT
      }
    }
  }
  attr {
    key: "field_delim"
    value {
      s: ","
    }
  }
}
node {
  name: "stack"
  op: "Pack"
  input: "DecodeCSV_1"
  input: "DecodeCSV_1:1"
  input: "DecodeCSV_1:2"
  attr {
    key: "N"
    value {
      i: 3
    }
  }
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "axis"
    value {
      i: 0
    }
  }
}
node {
  name: "shuffle/Const"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_BOOL
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_BOOL
        tensor_shape {
        }
        bool_val: true
      }
    }
  }
}
node {
  name: "shuffle/random_shuffle_queue"
  op: "RandomShuffleQueueV2"
  attr {
    key: "capacity"
    value {
      i: 15003
    }
  }
  attr {
    key: "component_types"
    value {
      list {
        type: DT_FLOAT
        type: DT_FLOAT
      }
    }
  }
  attr {
    key: "container"
    value {
      s: ""
    }
  }
  attr {
    key: "min_after_dequeue"
    value {
      i: 15000
    }
  }
  attr {
    key: "seed"
    value {
      i: 0
    }
  }
  attr {
    key: "seed2"
    value {
      i: 0
    }
  }
  attr {
    key: "shapes"
    value {
      list {
        shape {
          dim {
            size: 6
          }
        }
        shape {
          dim {
            size: 3
          }
        }
      }
    }
  }
  attr {
    key: "shared_name"
    value {
      s: ""
    }
  }
}
node {
  name: "shuffle/cond/Switch"
  op: "Switch"
  input: "shuffle/Const"
  input: "shuffle/Const"
  attr {
    key: "T"
    value {
      type: DT_BOOL
    }
  }
}
node {
  name: "shuffle/cond/switch_t"
  op: "Identity"
  input: "shuffle/cond/Switch:1"
  attr {
    key: "T"
    value {
      type: DT_BOOL
    }
  }
}
node {
  name: "shuffle/cond/switch_f"
  op: "Identity"
  input: "shuffle/cond/Switch"
  attr {
    key: "T"
    value {
      type: DT_BOOL
    }
  }
}
node {
  name: "shuffle/cond/pred_id"
  op: "Identity"
  input: "shuffle/Const"
  attr {
    key: "T"
    value {
      type: DT_BOOL
    }
  }
}
node {
  name: "shuffle/cond/random_shuffle_queue_enqueue/Switch"
  op: "Switch"
  input: "shuffle/random_shuffle_queue"
  input: "shuffle/cond/pred_id"
  attr {
    key: "T"
    value {
      type: DT_RESOURCE
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@shuffle/random_shuffle_queue"
      }
    }
  }
}
node {
  name: "shuffle/cond/random_shuffle_queue_enqueue/Switch_1"
  op: "Switch"
  input: "input_features"
  input: "shuffle/cond/pred_id"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@input_features"
      }
    }
  }
}
node {
  name: "shuffle/cond/random_shuffle_queue_enqueue/Switch_2"
  op: "Switch"
  input: "stack"
  input: "shuffle/cond/pred_id"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@stack"
      }
    }
  }
}
node {
  name: "shuffle/cond/random_shuffle_queue_enqueue"
  op: "QueueEnqueueV2"
  input: "shuffle/cond/random_shuffle_queue_enqueue/Switch:1"
  input: "shuffle/cond/random_shuffle_queue_enqueue/Switch_1:1"
  input: "shuffle/cond/random_shuffle_queue_enqueue/Switch_2:1"
  attr {
    key: "Tcomponents"
    value {
      list {
        type: DT_FLOAT
        type: DT_FLOAT
      }
    }
  }
  attr {
    key: "timeout_ms"
    value {
      i: -1
    }
  }
}
node {
  name: "shuffle/cond/control_dependency"
  op: "Identity"
  input: "shuffle/cond/switch_t"
  input: "^shuffle/cond/random_shuffle_queue_enqueue"
  attr {
    key: "T"
    value {
      type: DT_BOOL
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@shuffle/cond/switch_t"
      }
    }
  }
}
node {
  name: "shuffle/cond/NoOp"
  op: "NoOp"
  input: "^shuffle/cond/switch_f"
}
node {
  name: "shuffle/cond/control_dependency_1"
  op: "Identity"
  input: "shuffle/cond/switch_f"
  input: "^shuffle/cond/NoOp"
  attr {
    key: "T"
    value {
      type: DT_BOOL
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@shuffle/cond/switch_f"
      }
    }
  }
}
node {
  name: "shuffle/cond/Merge"
  op: "Merge"
  input: "shuffle/cond/control_dependency_1"
  input: "shuffle/cond/control_dependency"
  attr {
    key: "N"
    value {
      i: 2
    }
  }
  attr {
    key: "T"
    value {
      type: DT_BOOL
    }
  }
}
node {
  name: "shuffle/random_shuffle_queue_Close"
  op: "QueueCloseV2"
  input: "shuffle/random_shuffle_queue"
  attr {
    key: "cancel_pending_enqueues"
    value {
      b: false
    }
  }
}
node {
  name: "shuffle/random_shuffle_queue_Close_1"
  op: "QueueCloseV2"
  input: "shuffle/random_shuffle_queue"
  attr {
    key: "cancel_pending_enqueues"
    value {
      b: true
    }
  }
}
node {
  name: "shuffle/random_shuffle_queue_Size"
  op: "QueueSizeV2"
  input: "shuffle/random_shuffle_queue"
}
node {
  name: "shuffle/sub/y"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 15000
      }
    }
  }
}
node {
  name: "shuffle/sub"
  op: "Sub"
  input: "shuffle/random_shuffle_queue_Size"
  input: "shuffle/sub/y"
  attr {
    key: "T"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "shuffle/Maximum/x"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 0
      }
    }
  }
}
node {
  name: "shuffle/Maximum"
  op: "Maximum"
  input: "shuffle/Maximum/x"
  input: "shuffle/sub"
  attr {
    key: "T"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "shuffle/Cast"
  op: "Cast"
  input: "shuffle/Maximum"
  attr {
    key: "DstT"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "SrcT"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "shuffle/mul/y"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
        }
        float_val: 0.333333343267
      }
    }
  }
}
node {
  name: "shuffle/mul"
  op: "Mul"
  input: "shuffle/Cast"
  input: "shuffle/mul/y"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "shuffle/fraction_over_15000_of_3_full/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "shuffle/fraction_over_15000_of_3_full"
      }
    }
  }
}
node {
  name: "shuffle/fraction_over_15000_of_3_full"
  op: "ScalarSummary"
  input: "shuffle/fraction_over_15000_of_3_full/tags"
  input: "shuffle/mul"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "shuffle/n"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 1
      }
    }
  }
}
node {
  name: "shuffle"
  op: "QueueDequeueManyV2"
  input: "shuffle/random_shuffle_queue"
  input: "shuffle/n"
  attr {
    key: "component_types"
    value {
      list {
        type: DT_FLOAT
        type: DT_FLOAT
      }
    }
  }
  attr {
    key: "timeout_ms"
    value {
      i: -1
    }
  }
}
node {
  name: "example"
  op: "Identity"
  input: "shuffle"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "label"
  op: "Identity"
  input: "shuffle:1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "input/shape"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 2
          }
        }
        tensor_content: "\001\000\000\000\006\000\000\000"
      }
    }
  }
}
node {
  name: "input"
  op: "Reshape"
  input: "example"
  input: "input/shape"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tshape"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "layer1/weights/truncated_normal/shape"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 2
          }
        }
        tensor_content: "\006\000\000\000\n\000\000\000"
      }
    }
  }
}
node {
  name: "layer1/weights/truncated_normal/mean"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
        }
        float_val: 0.0
      }
    }
  }
}
node {
  name: "layer1/weights/truncated_normal/stddev"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
        }
        float_val: 0.10000000149
      }
    }
  }
}
node {
  name: "layer1/weights/truncated_normal/TruncatedNormal"
  op: "TruncatedNormal"
  input: "layer1/weights/truncated_normal/shape"
  attr {
    key: "T"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "seed"
    value {
      i: 0
    }
  }
  attr {
    key: "seed2"
    value {
      i: 0
    }
  }
}
node {
  name: "layer1/weights/truncated_normal/mul"
  op: "Mul"
  input: "layer1/weights/truncated_normal/TruncatedNormal"
  input: "layer1/weights/truncated_normal/stddev"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer1/weights/truncated_normal"
  op: "Add"
  input: "layer1/weights/truncated_normal/mul"
  input: "layer1/weights/truncated_normal/mean"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer1/weights/Variable"
  op: "VariableV2"
  attr {
    key: "container"
    value {
      s: ""
    }
  }
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "shape"
    value {
      shape {
        dim {
          size: 6
        }
        dim {
          size: 10
        }
      }
    }
  }
  attr {
    key: "shared_name"
    value {
      s: ""
    }
  }
}
node {
  name: "layer1/weights/Variable/Assign"
  op: "Assign"
  input: "layer1/weights/Variable"
  input: "layer1/weights/truncated_normal"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer1/weights/Variable"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: true
    }
  }
  attr {
    key: "validate_shape"
    value {
      b: true
    }
  }
}
node {
  name: "layer1/weights/Variable/read"
  op: "Identity"
  input: "layer1/weights/Variable"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer1/weights/Variable"
      }
    }
  }
}
node {
  name: "layer1/weights/summaries/Rank"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 2
      }
    }
  }
}
node {
  name: "layer1/weights/summaries/range/start"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 0
      }
    }
  }
}
node {
  name: "layer1/weights/summaries/range/delta"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 1
      }
    }
  }
}
node {
  name: "layer1/weights/summaries/range"
  op: "Range"
  input: "layer1/weights/summaries/range/start"
  input: "layer1/weights/summaries/Rank"
  input: "layer1/weights/summaries/range/delta"
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "layer1/weights/summaries/Mean"
  op: "Mean"
  input: "layer1/weights/Variable/read"
  input: "layer1/weights/summaries/range"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "layer1/weights/summaries/mean/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer1/weights/summaries/mean"
      }
    }
  }
}
node {
  name: "layer1/weights/summaries/mean"
  op: "ScalarSummary"
  input: "layer1/weights/summaries/mean/tags"
  input: "layer1/weights/summaries/Mean"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer1/weights/summaries/stddev/sub"
  op: "Sub"
  input: "layer1/weights/Variable/read"
  input: "layer1/weights/summaries/Mean"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer1/weights/summaries/stddev/Square"
  op: "Square"
  input: "layer1/weights/summaries/stddev/sub"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer1/weights/summaries/stddev/Const"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 2
          }
        }
        tensor_content: "\000\000\000\000\001\000\000\000"
      }
    }
  }
}
node {
  name: "layer1/weights/summaries/stddev/Mean"
  op: "Mean"
  input: "layer1/weights/summaries/stddev/Square"
  input: "layer1/weights/summaries/stddev/Const"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "layer1/weights/summaries/stddev/Sqrt"
  op: "Sqrt"
  input: "layer1/weights/summaries/stddev/Mean"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer1/weights/summaries/stddev_1/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer1/weights/summaries/stddev_1"
      }
    }
  }
}
node {
  name: "layer1/weights/summaries/stddev_1"
  op: "ScalarSummary"
  input: "layer1/weights/summaries/stddev_1/tags"
  input: "layer1/weights/summaries/stddev/Sqrt"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer1/weights/summaries/Rank_1"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 2
      }
    }
  }
}
node {
  name: "layer1/weights/summaries/range_1/start"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 0
      }
    }
  }
}
node {
  name: "layer1/weights/summaries/range_1/delta"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 1
      }
    }
  }
}
node {
  name: "layer1/weights/summaries/range_1"
  op: "Range"
  input: "layer1/weights/summaries/range_1/start"
  input: "layer1/weights/summaries/Rank_1"
  input: "layer1/weights/summaries/range_1/delta"
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "layer1/weights/summaries/Max"
  op: "Max"
  input: "layer1/weights/Variable/read"
  input: "layer1/weights/summaries/range_1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "layer1/weights/summaries/max/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer1/weights/summaries/max"
      }
    }
  }
}
node {
  name: "layer1/weights/summaries/max"
  op: "ScalarSummary"
  input: "layer1/weights/summaries/max/tags"
  input: "layer1/weights/summaries/Max"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer1/weights/summaries/Rank_2"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 2
      }
    }
  }
}
node {
  name: "layer1/weights/summaries/range_2/start"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 0
      }
    }
  }
}
node {
  name: "layer1/weights/summaries/range_2/delta"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 1
      }
    }
  }
}
node {
  name: "layer1/weights/summaries/range_2"
  op: "Range"
  input: "layer1/weights/summaries/range_2/start"
  input: "layer1/weights/summaries/Rank_2"
  input: "layer1/weights/summaries/range_2/delta"
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "layer1/weights/summaries/Min"
  op: "Min"
  input: "layer1/weights/Variable/read"
  input: "layer1/weights/summaries/range_2"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "layer1/weights/summaries/min/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer1/weights/summaries/min"
      }
    }
  }
}
node {
  name: "layer1/weights/summaries/min"
  op: "ScalarSummary"
  input: "layer1/weights/summaries/min/tags"
  input: "layer1/weights/summaries/Min"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer1/weights/summaries/histogram/tag"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer1/weights/summaries/histogram"
      }
    }
  }
}
node {
  name: "layer1/weights/summaries/histogram"
  op: "HistogramSummary"
  input: "layer1/weights/summaries/histogram/tag"
  input: "layer1/weights/Variable/read"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer1/biases/Const"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
          dim {
            size: 10
          }
        }
        float_val: 0.10000000149
      }
    }
  }
}
node {
  name: "layer1/biases/Variable"
  op: "VariableV2"
  attr {
    key: "container"
    value {
      s: ""
    }
  }
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "shape"
    value {
      shape {
        dim {
          size: 10
        }
      }
    }
  }
  attr {
    key: "shared_name"
    value {
      s: ""
    }
  }
}
node {
  name: "layer1/biases/Variable/Assign"
  op: "Assign"
  input: "layer1/biases/Variable"
  input: "layer1/biases/Const"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer1/biases/Variable"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: true
    }
  }
  attr {
    key: "validate_shape"
    value {
      b: true
    }
  }
}
node {
  name: "layer1/biases/Variable/read"
  op: "Identity"
  input: "layer1/biases/Variable"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer1/biases/Variable"
      }
    }
  }
}
node {
  name: "layer1/biases/summaries/Rank"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 1
      }
    }
  }
}
node {
  name: "layer1/biases/summaries/range/start"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 0
      }
    }
  }
}
node {
  name: "layer1/biases/summaries/range/delta"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 1
      }
    }
  }
}
node {
  name: "layer1/biases/summaries/range"
  op: "Range"
  input: "layer1/biases/summaries/range/start"
  input: "layer1/biases/summaries/Rank"
  input: "layer1/biases/summaries/range/delta"
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "layer1/biases/summaries/Mean"
  op: "Mean"
  input: "layer1/biases/Variable/read"
  input: "layer1/biases/summaries/range"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "layer1/biases/summaries/mean/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer1/biases/summaries/mean"
      }
    }
  }
}
node {
  name: "layer1/biases/summaries/mean"
  op: "ScalarSummary"
  input: "layer1/biases/summaries/mean/tags"
  input: "layer1/biases/summaries/Mean"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer1/biases/summaries/stddev/sub"
  op: "Sub"
  input: "layer1/biases/Variable/read"
  input: "layer1/biases/summaries/Mean"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer1/biases/summaries/stddev/Square"
  op: "Square"
  input: "layer1/biases/summaries/stddev/sub"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer1/biases/summaries/stddev/Const"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 1
          }
        }
        int_val: 0
      }
    }
  }
}
node {
  name: "layer1/biases/summaries/stddev/Mean"
  op: "Mean"
  input: "layer1/biases/summaries/stddev/Square"
  input: "layer1/biases/summaries/stddev/Const"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "layer1/biases/summaries/stddev/Sqrt"
  op: "Sqrt"
  input: "layer1/biases/summaries/stddev/Mean"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer1/biases/summaries/stddev_1/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer1/biases/summaries/stddev_1"
      }
    }
  }
}
node {
  name: "layer1/biases/summaries/stddev_1"
  op: "ScalarSummary"
  input: "layer1/biases/summaries/stddev_1/tags"
  input: "layer1/biases/summaries/stddev/Sqrt"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer1/biases/summaries/Rank_1"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 1
      }
    }
  }
}
node {
  name: "layer1/biases/summaries/range_1/start"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 0
      }
    }
  }
}
node {
  name: "layer1/biases/summaries/range_1/delta"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 1
      }
    }
  }
}
node {
  name: "layer1/biases/summaries/range_1"
  op: "Range"
  input: "layer1/biases/summaries/range_1/start"
  input: "layer1/biases/summaries/Rank_1"
  input: "layer1/biases/summaries/range_1/delta"
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "layer1/biases/summaries/Max"
  op: "Max"
  input: "layer1/biases/Variable/read"
  input: "layer1/biases/summaries/range_1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "layer1/biases/summaries/max/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer1/biases/summaries/max"
      }
    }
  }
}
node {
  name: "layer1/biases/summaries/max"
  op: "ScalarSummary"
  input: "layer1/biases/summaries/max/tags"
  input: "layer1/biases/summaries/Max"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer1/biases/summaries/Rank_2"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 1
      }
    }
  }
}
node {
  name: "layer1/biases/summaries/range_2/start"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 0
      }
    }
  }
}
node {
  name: "layer1/biases/summaries/range_2/delta"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 1
      }
    }
  }
}
node {
  name: "layer1/biases/summaries/range_2"
  op: "Range"
  input: "layer1/biases/summaries/range_2/start"
  input: "layer1/biases/summaries/Rank_2"
  input: "layer1/biases/summaries/range_2/delta"
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "layer1/biases/summaries/Min"
  op: "Min"
  input: "layer1/biases/Variable/read"
  input: "layer1/biases/summaries/range_2"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "layer1/biases/summaries/min/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer1/biases/summaries/min"
      }
    }
  }
}
node {
  name: "layer1/biases/summaries/min"
  op: "ScalarSummary"
  input: "layer1/biases/summaries/min/tags"
  input: "layer1/biases/summaries/Min"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer1/biases/summaries/histogram/tag"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer1/biases/summaries/histogram"
      }
    }
  }
}
node {
  name: "layer1/biases/summaries/histogram"
  op: "HistogramSummary"
  input: "layer1/biases/summaries/histogram/tag"
  input: "layer1/biases/Variable/read"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer1/Wx_plus_b/MatMul"
  op: "MatMul"
  input: "input"
  input: "layer1/weights/Variable/read"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "transpose_a"
    value {
      b: false
    }
  }
  attr {
    key: "transpose_b"
    value {
      b: false
    }
  }
}
node {
  name: "layer1/Wx_plus_b/add"
  op: "Add"
  input: "layer1/Wx_plus_b/MatMul"
  input: "layer1/biases/Variable/read"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer1/Wx_plus_b/pre_activations/tag"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer1/Wx_plus_b/pre_activations"
      }
    }
  }
}
node {
  name: "layer1/Wx_plus_b/pre_activations"
  op: "HistogramSummary"
  input: "layer1/Wx_plus_b/pre_activations/tag"
  input: "layer1/Wx_plus_b/add"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer1/activation"
  op: "Relu"
  input: "layer1/Wx_plus_b/add"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer1/activations/tag"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer1/activations"
      }
    }
  }
}
node {
  name: "layer1/activations"
  op: "HistogramSummary"
  input: "layer1/activations/tag"
  input: "layer1/activation"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "input_1/shape"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 2
          }
        }
        tensor_content: "\001\000\000\000\n\000\000\000"
      }
    }
  }
}
node {
  name: "input_1"
  op: "Reshape"
  input: "layer1/activation"
  input: "input_1/shape"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tshape"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "layer2/weights/truncated_normal/shape"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 2
          }
        }
        tensor_content: "\n\000\000\000\n\000\000\000"
      }
    }
  }
}
node {
  name: "layer2/weights/truncated_normal/mean"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
        }
        float_val: 0.0
      }
    }
  }
}
node {
  name: "layer2/weights/truncated_normal/stddev"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
        }
        float_val: 0.10000000149
      }
    }
  }
}
node {
  name: "layer2/weights/truncated_normal/TruncatedNormal"
  op: "TruncatedNormal"
  input: "layer2/weights/truncated_normal/shape"
  attr {
    key: "T"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "seed"
    value {
      i: 0
    }
  }
  attr {
    key: "seed2"
    value {
      i: 0
    }
  }
}
node {
  name: "layer2/weights/truncated_normal/mul"
  op: "Mul"
  input: "layer2/weights/truncated_normal/TruncatedNormal"
  input: "layer2/weights/truncated_normal/stddev"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer2/weights/truncated_normal"
  op: "Add"
  input: "layer2/weights/truncated_normal/mul"
  input: "layer2/weights/truncated_normal/mean"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer2/weights/Variable"
  op: "VariableV2"
  attr {
    key: "container"
    value {
      s: ""
    }
  }
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "shape"
    value {
      shape {
        dim {
          size: 10
        }
        dim {
          size: 10
        }
      }
    }
  }
  attr {
    key: "shared_name"
    value {
      s: ""
    }
  }
}
node {
  name: "layer2/weights/Variable/Assign"
  op: "Assign"
  input: "layer2/weights/Variable"
  input: "layer2/weights/truncated_normal"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer2/weights/Variable"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: true
    }
  }
  attr {
    key: "validate_shape"
    value {
      b: true
    }
  }
}
node {
  name: "layer2/weights/Variable/read"
  op: "Identity"
  input: "layer2/weights/Variable"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer2/weights/Variable"
      }
    }
  }
}
node {
  name: "layer2/weights/summaries/Rank"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 2
      }
    }
  }
}
node {
  name: "layer2/weights/summaries/range/start"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 0
      }
    }
  }
}
node {
  name: "layer2/weights/summaries/range/delta"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 1
      }
    }
  }
}
node {
  name: "layer2/weights/summaries/range"
  op: "Range"
  input: "layer2/weights/summaries/range/start"
  input: "layer2/weights/summaries/Rank"
  input: "layer2/weights/summaries/range/delta"
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "layer2/weights/summaries/Mean"
  op: "Mean"
  input: "layer2/weights/Variable/read"
  input: "layer2/weights/summaries/range"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "layer2/weights/summaries/mean/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer2/weights/summaries/mean"
      }
    }
  }
}
node {
  name: "layer2/weights/summaries/mean"
  op: "ScalarSummary"
  input: "layer2/weights/summaries/mean/tags"
  input: "layer2/weights/summaries/Mean"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer2/weights/summaries/stddev/sub"
  op: "Sub"
  input: "layer2/weights/Variable/read"
  input: "layer2/weights/summaries/Mean"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer2/weights/summaries/stddev/Square"
  op: "Square"
  input: "layer2/weights/summaries/stddev/sub"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer2/weights/summaries/stddev/Const"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 2
          }
        }
        tensor_content: "\000\000\000\000\001\000\000\000"
      }
    }
  }
}
node {
  name: "layer2/weights/summaries/stddev/Mean"
  op: "Mean"
  input: "layer2/weights/summaries/stddev/Square"
  input: "layer2/weights/summaries/stddev/Const"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "layer2/weights/summaries/stddev/Sqrt"
  op: "Sqrt"
  input: "layer2/weights/summaries/stddev/Mean"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer2/weights/summaries/stddev_1/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer2/weights/summaries/stddev_1"
      }
    }
  }
}
node {
  name: "layer2/weights/summaries/stddev_1"
  op: "ScalarSummary"
  input: "layer2/weights/summaries/stddev_1/tags"
  input: "layer2/weights/summaries/stddev/Sqrt"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer2/weights/summaries/Rank_1"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 2
      }
    }
  }
}
node {
  name: "layer2/weights/summaries/range_1/start"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 0
      }
    }
  }
}
node {
  name: "layer2/weights/summaries/range_1/delta"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 1
      }
    }
  }
}
node {
  name: "layer2/weights/summaries/range_1"
  op: "Range"
  input: "layer2/weights/summaries/range_1/start"
  input: "layer2/weights/summaries/Rank_1"
  input: "layer2/weights/summaries/range_1/delta"
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "layer2/weights/summaries/Max"
  op: "Max"
  input: "layer2/weights/Variable/read"
  input: "layer2/weights/summaries/range_1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "layer2/weights/summaries/max/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer2/weights/summaries/max"
      }
    }
  }
}
node {
  name: "layer2/weights/summaries/max"
  op: "ScalarSummary"
  input: "layer2/weights/summaries/max/tags"
  input: "layer2/weights/summaries/Max"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer2/weights/summaries/Rank_2"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 2
      }
    }
  }
}
node {
  name: "layer2/weights/summaries/range_2/start"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 0
      }
    }
  }
}
node {
  name: "layer2/weights/summaries/range_2/delta"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 1
      }
    }
  }
}
node {
  name: "layer2/weights/summaries/range_2"
  op: "Range"
  input: "layer2/weights/summaries/range_2/start"
  input: "layer2/weights/summaries/Rank_2"
  input: "layer2/weights/summaries/range_2/delta"
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "layer2/weights/summaries/Min"
  op: "Min"
  input: "layer2/weights/Variable/read"
  input: "layer2/weights/summaries/range_2"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "layer2/weights/summaries/min/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer2/weights/summaries/min"
      }
    }
  }
}
node {
  name: "layer2/weights/summaries/min"
  op: "ScalarSummary"
  input: "layer2/weights/summaries/min/tags"
  input: "layer2/weights/summaries/Min"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer2/weights/summaries/histogram/tag"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer2/weights/summaries/histogram"
      }
    }
  }
}
node {
  name: "layer2/weights/summaries/histogram"
  op: "HistogramSummary"
  input: "layer2/weights/summaries/histogram/tag"
  input: "layer2/weights/Variable/read"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer2/biases/Const"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
          dim {
            size: 10
          }
        }
        float_val: 0.10000000149
      }
    }
  }
}
node {
  name: "layer2/biases/Variable"
  op: "VariableV2"
  attr {
    key: "container"
    value {
      s: ""
    }
  }
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "shape"
    value {
      shape {
        dim {
          size: 10
        }
      }
    }
  }
  attr {
    key: "shared_name"
    value {
      s: ""
    }
  }
}
node {
  name: "layer2/biases/Variable/Assign"
  op: "Assign"
  input: "layer2/biases/Variable"
  input: "layer2/biases/Const"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer2/biases/Variable"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: true
    }
  }
  attr {
    key: "validate_shape"
    value {
      b: true
    }
  }
}
node {
  name: "layer2/biases/Variable/read"
  op: "Identity"
  input: "layer2/biases/Variable"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer2/biases/Variable"
      }
    }
  }
}
node {
  name: "layer2/biases/summaries/Rank"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 1
      }
    }
  }
}
node {
  name: "layer2/biases/summaries/range/start"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 0
      }
    }
  }
}
node {
  name: "layer2/biases/summaries/range/delta"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 1
      }
    }
  }
}
node {
  name: "layer2/biases/summaries/range"
  op: "Range"
  input: "layer2/biases/summaries/range/start"
  input: "layer2/biases/summaries/Rank"
  input: "layer2/biases/summaries/range/delta"
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "layer2/biases/summaries/Mean"
  op: "Mean"
  input: "layer2/biases/Variable/read"
  input: "layer2/biases/summaries/range"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "layer2/biases/summaries/mean/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer2/biases/summaries/mean"
      }
    }
  }
}
node {
  name: "layer2/biases/summaries/mean"
  op: "ScalarSummary"
  input: "layer2/biases/summaries/mean/tags"
  input: "layer2/biases/summaries/Mean"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer2/biases/summaries/stddev/sub"
  op: "Sub"
  input: "layer2/biases/Variable/read"
  input: "layer2/biases/summaries/Mean"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer2/biases/summaries/stddev/Square"
  op: "Square"
  input: "layer2/biases/summaries/stddev/sub"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer2/biases/summaries/stddev/Const"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 1
          }
        }
        int_val: 0
      }
    }
  }
}
node {
  name: "layer2/biases/summaries/stddev/Mean"
  op: "Mean"
  input: "layer2/biases/summaries/stddev/Square"
  input: "layer2/biases/summaries/stddev/Const"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "layer2/biases/summaries/stddev/Sqrt"
  op: "Sqrt"
  input: "layer2/biases/summaries/stddev/Mean"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer2/biases/summaries/stddev_1/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer2/biases/summaries/stddev_1"
      }
    }
  }
}
node {
  name: "layer2/biases/summaries/stddev_1"
  op: "ScalarSummary"
  input: "layer2/biases/summaries/stddev_1/tags"
  input: "layer2/biases/summaries/stddev/Sqrt"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer2/biases/summaries/Rank_1"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 1
      }
    }
  }
}
node {
  name: "layer2/biases/summaries/range_1/start"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 0
      }
    }
  }
}
node {
  name: "layer2/biases/summaries/range_1/delta"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 1
      }
    }
  }
}
node {
  name: "layer2/biases/summaries/range_1"
  op: "Range"
  input: "layer2/biases/summaries/range_1/start"
  input: "layer2/biases/summaries/Rank_1"
  input: "layer2/biases/summaries/range_1/delta"
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "layer2/biases/summaries/Max"
  op: "Max"
  input: "layer2/biases/Variable/read"
  input: "layer2/biases/summaries/range_1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "layer2/biases/summaries/max/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer2/biases/summaries/max"
      }
    }
  }
}
node {
  name: "layer2/biases/summaries/max"
  op: "ScalarSummary"
  input: "layer2/biases/summaries/max/tags"
  input: "layer2/biases/summaries/Max"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer2/biases/summaries/Rank_2"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 1
      }
    }
  }
}
node {
  name: "layer2/biases/summaries/range_2/start"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 0
      }
    }
  }
}
node {
  name: "layer2/biases/summaries/range_2/delta"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 1
      }
    }
  }
}
node {
  name: "layer2/biases/summaries/range_2"
  op: "Range"
  input: "layer2/biases/summaries/range_2/start"
  input: "layer2/biases/summaries/Rank_2"
  input: "layer2/biases/summaries/range_2/delta"
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "layer2/biases/summaries/Min"
  op: "Min"
  input: "layer2/biases/Variable/read"
  input: "layer2/biases/summaries/range_2"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "layer2/biases/summaries/min/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer2/biases/summaries/min"
      }
    }
  }
}
node {
  name: "layer2/biases/summaries/min"
  op: "ScalarSummary"
  input: "layer2/biases/summaries/min/tags"
  input: "layer2/biases/summaries/Min"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer2/biases/summaries/histogram/tag"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer2/biases/summaries/histogram"
      }
    }
  }
}
node {
  name: "layer2/biases/summaries/histogram"
  op: "HistogramSummary"
  input: "layer2/biases/summaries/histogram/tag"
  input: "layer2/biases/Variable/read"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer2/Wx_plus_b/MatMul"
  op: "MatMul"
  input: "input_1"
  input: "layer2/weights/Variable/read"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "transpose_a"
    value {
      b: false
    }
  }
  attr {
    key: "transpose_b"
    value {
      b: false
    }
  }
}
node {
  name: "layer2/Wx_plus_b/add"
  op: "Add"
  input: "layer2/Wx_plus_b/MatMul"
  input: "layer2/biases/Variable/read"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer2/Wx_plus_b/pre_activations/tag"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer2/Wx_plus_b/pre_activations"
      }
    }
  }
}
node {
  name: "layer2/Wx_plus_b/pre_activations"
  op: "HistogramSummary"
  input: "layer2/Wx_plus_b/pre_activations/tag"
  input: "layer2/Wx_plus_b/add"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer2/activation"
  op: "Relu"
  input: "layer2/Wx_plus_b/add"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer2/activations/tag"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer2/activations"
      }
    }
  }
}
node {
  name: "layer2/activations"
  op: "HistogramSummary"
  input: "layer2/activations/tag"
  input: "layer2/activation"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "input_2/shape"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 2
          }
        }
        tensor_content: "\001\000\000\000\n\000\000\000"
      }
    }
  }
}
node {
  name: "input_2"
  op: "Reshape"
  input: "layer2/activation"
  input: "input_2/shape"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tshape"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "layer3/weights/truncated_normal/shape"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 2
          }
        }
        tensor_content: "\n\000\000\000\003\000\000\000"
      }
    }
  }
}
node {
  name: "layer3/weights/truncated_normal/mean"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
        }
        float_val: 0.0
      }
    }
  }
}
node {
  name: "layer3/weights/truncated_normal/stddev"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
        }
        float_val: 0.10000000149
      }
    }
  }
}
node {
  name: "layer3/weights/truncated_normal/TruncatedNormal"
  op: "TruncatedNormal"
  input: "layer3/weights/truncated_normal/shape"
  attr {
    key: "T"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "seed"
    value {
      i: 0
    }
  }
  attr {
    key: "seed2"
    value {
      i: 0
    }
  }
}
node {
  name: "layer3/weights/truncated_normal/mul"
  op: "Mul"
  input: "layer3/weights/truncated_normal/TruncatedNormal"
  input: "layer3/weights/truncated_normal/stddev"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer3/weights/truncated_normal"
  op: "Add"
  input: "layer3/weights/truncated_normal/mul"
  input: "layer3/weights/truncated_normal/mean"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer3/weights/Variable"
  op: "VariableV2"
  attr {
    key: "container"
    value {
      s: ""
    }
  }
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "shape"
    value {
      shape {
        dim {
          size: 10
        }
        dim {
          size: 3
        }
      }
    }
  }
  attr {
    key: "shared_name"
    value {
      s: ""
    }
  }
}
node {
  name: "layer3/weights/Variable/Assign"
  op: "Assign"
  input: "layer3/weights/Variable"
  input: "layer3/weights/truncated_normal"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer3/weights/Variable"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: true
    }
  }
  attr {
    key: "validate_shape"
    value {
      b: true
    }
  }
}
node {
  name: "layer3/weights/Variable/read"
  op: "Identity"
  input: "layer3/weights/Variable"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer3/weights/Variable"
      }
    }
  }
}
node {
  name: "layer3/weights/summaries/Rank"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 2
      }
    }
  }
}
node {
  name: "layer3/weights/summaries/range/start"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 0
      }
    }
  }
}
node {
  name: "layer3/weights/summaries/range/delta"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 1
      }
    }
  }
}
node {
  name: "layer3/weights/summaries/range"
  op: "Range"
  input: "layer3/weights/summaries/range/start"
  input: "layer3/weights/summaries/Rank"
  input: "layer3/weights/summaries/range/delta"
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "layer3/weights/summaries/Mean"
  op: "Mean"
  input: "layer3/weights/Variable/read"
  input: "layer3/weights/summaries/range"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "layer3/weights/summaries/mean/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer3/weights/summaries/mean"
      }
    }
  }
}
node {
  name: "layer3/weights/summaries/mean"
  op: "ScalarSummary"
  input: "layer3/weights/summaries/mean/tags"
  input: "layer3/weights/summaries/Mean"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer3/weights/summaries/stddev/sub"
  op: "Sub"
  input: "layer3/weights/Variable/read"
  input: "layer3/weights/summaries/Mean"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer3/weights/summaries/stddev/Square"
  op: "Square"
  input: "layer3/weights/summaries/stddev/sub"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer3/weights/summaries/stddev/Const"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 2
          }
        }
        tensor_content: "\000\000\000\000\001\000\000\000"
      }
    }
  }
}
node {
  name: "layer3/weights/summaries/stddev/Mean"
  op: "Mean"
  input: "layer3/weights/summaries/stddev/Square"
  input: "layer3/weights/summaries/stddev/Const"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "layer3/weights/summaries/stddev/Sqrt"
  op: "Sqrt"
  input: "layer3/weights/summaries/stddev/Mean"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer3/weights/summaries/stddev_1/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer3/weights/summaries/stddev_1"
      }
    }
  }
}
node {
  name: "layer3/weights/summaries/stddev_1"
  op: "ScalarSummary"
  input: "layer3/weights/summaries/stddev_1/tags"
  input: "layer3/weights/summaries/stddev/Sqrt"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer3/weights/summaries/Rank_1"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 2
      }
    }
  }
}
node {
  name: "layer3/weights/summaries/range_1/start"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 0
      }
    }
  }
}
node {
  name: "layer3/weights/summaries/range_1/delta"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 1
      }
    }
  }
}
node {
  name: "layer3/weights/summaries/range_1"
  op: "Range"
  input: "layer3/weights/summaries/range_1/start"
  input: "layer3/weights/summaries/Rank_1"
  input: "layer3/weights/summaries/range_1/delta"
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "layer3/weights/summaries/Max"
  op: "Max"
  input: "layer3/weights/Variable/read"
  input: "layer3/weights/summaries/range_1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "layer3/weights/summaries/max/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer3/weights/summaries/max"
      }
    }
  }
}
node {
  name: "layer3/weights/summaries/max"
  op: "ScalarSummary"
  input: "layer3/weights/summaries/max/tags"
  input: "layer3/weights/summaries/Max"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer3/weights/summaries/Rank_2"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 2
      }
    }
  }
}
node {
  name: "layer3/weights/summaries/range_2/start"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 0
      }
    }
  }
}
node {
  name: "layer3/weights/summaries/range_2/delta"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 1
      }
    }
  }
}
node {
  name: "layer3/weights/summaries/range_2"
  op: "Range"
  input: "layer3/weights/summaries/range_2/start"
  input: "layer3/weights/summaries/Rank_2"
  input: "layer3/weights/summaries/range_2/delta"
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "layer3/weights/summaries/Min"
  op: "Min"
  input: "layer3/weights/Variable/read"
  input: "layer3/weights/summaries/range_2"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "layer3/weights/summaries/min/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer3/weights/summaries/min"
      }
    }
  }
}
node {
  name: "layer3/weights/summaries/min"
  op: "ScalarSummary"
  input: "layer3/weights/summaries/min/tags"
  input: "layer3/weights/summaries/Min"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer3/weights/summaries/histogram/tag"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer3/weights/summaries/histogram"
      }
    }
  }
}
node {
  name: "layer3/weights/summaries/histogram"
  op: "HistogramSummary"
  input: "layer3/weights/summaries/histogram/tag"
  input: "layer3/weights/Variable/read"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer3/biases/Const"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
          dim {
            size: 3
          }
        }
        float_val: 0.10000000149
      }
    }
  }
}
node {
  name: "layer3/biases/Variable"
  op: "VariableV2"
  attr {
    key: "container"
    value {
      s: ""
    }
  }
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "shape"
    value {
      shape {
        dim {
          size: 3
        }
      }
    }
  }
  attr {
    key: "shared_name"
    value {
      s: ""
    }
  }
}
node {
  name: "layer3/biases/Variable/Assign"
  op: "Assign"
  input: "layer3/biases/Variable"
  input: "layer3/biases/Const"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer3/biases/Variable"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: true
    }
  }
  attr {
    key: "validate_shape"
    value {
      b: true
    }
  }
}
node {
  name: "layer3/biases/Variable/read"
  op: "Identity"
  input: "layer3/biases/Variable"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer3/biases/Variable"
      }
    }
  }
}
node {
  name: "layer3/biases/summaries/Rank"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 1
      }
    }
  }
}
node {
  name: "layer3/biases/summaries/range/start"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 0
      }
    }
  }
}
node {
  name: "layer3/biases/summaries/range/delta"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 1
      }
    }
  }
}
node {
  name: "layer3/biases/summaries/range"
  op: "Range"
  input: "layer3/biases/summaries/range/start"
  input: "layer3/biases/summaries/Rank"
  input: "layer3/biases/summaries/range/delta"
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "layer3/biases/summaries/Mean"
  op: "Mean"
  input: "layer3/biases/Variable/read"
  input: "layer3/biases/summaries/range"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "layer3/biases/summaries/mean/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer3/biases/summaries/mean"
      }
    }
  }
}
node {
  name: "layer3/biases/summaries/mean"
  op: "ScalarSummary"
  input: "layer3/biases/summaries/mean/tags"
  input: "layer3/biases/summaries/Mean"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer3/biases/summaries/stddev/sub"
  op: "Sub"
  input: "layer3/biases/Variable/read"
  input: "layer3/biases/summaries/Mean"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer3/biases/summaries/stddev/Square"
  op: "Square"
  input: "layer3/biases/summaries/stddev/sub"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer3/biases/summaries/stddev/Const"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 1
          }
        }
        int_val: 0
      }
    }
  }
}
node {
  name: "layer3/biases/summaries/stddev/Mean"
  op: "Mean"
  input: "layer3/biases/summaries/stddev/Square"
  input: "layer3/biases/summaries/stddev/Const"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "layer3/biases/summaries/stddev/Sqrt"
  op: "Sqrt"
  input: "layer3/biases/summaries/stddev/Mean"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer3/biases/summaries/stddev_1/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer3/biases/summaries/stddev_1"
      }
    }
  }
}
node {
  name: "layer3/biases/summaries/stddev_1"
  op: "ScalarSummary"
  input: "layer3/biases/summaries/stddev_1/tags"
  input: "layer3/biases/summaries/stddev/Sqrt"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer3/biases/summaries/Rank_1"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 1
      }
    }
  }
}
node {
  name: "layer3/biases/summaries/range_1/start"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 0
      }
    }
  }
}
node {
  name: "layer3/biases/summaries/range_1/delta"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 1
      }
    }
  }
}
node {
  name: "layer3/biases/summaries/range_1"
  op: "Range"
  input: "layer3/biases/summaries/range_1/start"
  input: "layer3/biases/summaries/Rank_1"
  input: "layer3/biases/summaries/range_1/delta"
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "layer3/biases/summaries/Max"
  op: "Max"
  input: "layer3/biases/Variable/read"
  input: "layer3/biases/summaries/range_1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "layer3/biases/summaries/max/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer3/biases/summaries/max"
      }
    }
  }
}
node {
  name: "layer3/biases/summaries/max"
  op: "ScalarSummary"
  input: "layer3/biases/summaries/max/tags"
  input: "layer3/biases/summaries/Max"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer3/biases/summaries/Rank_2"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 1
      }
    }
  }
}
node {
  name: "layer3/biases/summaries/range_2/start"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 0
      }
    }
  }
}
node {
  name: "layer3/biases/summaries/range_2/delta"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 1
      }
    }
  }
}
node {
  name: "layer3/biases/summaries/range_2"
  op: "Range"
  input: "layer3/biases/summaries/range_2/start"
  input: "layer3/biases/summaries/Rank_2"
  input: "layer3/biases/summaries/range_2/delta"
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "layer3/biases/summaries/Min"
  op: "Min"
  input: "layer3/biases/Variable/read"
  input: "layer3/biases/summaries/range_2"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "layer3/biases/summaries/min/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer3/biases/summaries/min"
      }
    }
  }
}
node {
  name: "layer3/biases/summaries/min"
  op: "ScalarSummary"
  input: "layer3/biases/summaries/min/tags"
  input: "layer3/biases/summaries/Min"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer3/biases/summaries/histogram/tag"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer3/biases/summaries/histogram"
      }
    }
  }
}
node {
  name: "layer3/biases/summaries/histogram"
  op: "HistogramSummary"
  input: "layer3/biases/summaries/histogram/tag"
  input: "layer3/biases/Variable/read"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer3/Wx_plus_b/MatMul"
  op: "MatMul"
  input: "input_2"
  input: "layer3/weights/Variable/read"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "transpose_a"
    value {
      b: false
    }
  }
  attr {
    key: "transpose_b"
    value {
      b: false
    }
  }
}
node {
  name: "layer3/Wx_plus_b/add"
  op: "Add"
  input: "layer3/Wx_plus_b/MatMul"
  input: "layer3/biases/Variable/read"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer3/Wx_plus_b/pre_activations/tag"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer3/Wx_plus_b/pre_activations"
      }
    }
  }
}
node {
  name: "layer3/Wx_plus_b/pre_activations"
  op: "HistogramSummary"
  input: "layer3/Wx_plus_b/pre_activations/tag"
  input: "layer3/Wx_plus_b/add"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer3/activation"
  op: "Identity"
  input: "layer3/Wx_plus_b/add"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "layer3/activations/tag"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "layer3/activations"
      }
    }
  }
}
node {
  name: "layer3/activations"
  op: "HistogramSummary"
  input: "layer3/activations/tag"
  input: "layer3/activation"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "pred/summaries/Const"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 2
          }
        }
        tensor_content: "\000\000\000\000\001\000\000\000"
      }
    }
  }
}
node {
  name: "pred/summaries/Mean"
  op: "Mean"
  input: "layer3/activation"
  input: "pred/summaries/Const"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "pred/summaries/mean/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "pred/summaries/mean"
      }
    }
  }
}
node {
  name: "pred/summaries/mean"
  op: "ScalarSummary"
  input: "pred/summaries/mean/tags"
  input: "pred/summaries/Mean"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "pred/summaries/stddev/sub"
  op: "Sub"
  input: "layer3/activation"
  input: "pred/summaries/Mean"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "pred/summaries/stddev/Square"
  op: "Square"
  input: "pred/summaries/stddev/sub"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "pred/summaries/stddev/Const"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 2
          }
        }
        tensor_content: "\000\000\000\000\001\000\000\000"
      }
    }
  }
}
node {
  name: "pred/summaries/stddev/Mean"
  op: "Mean"
  input: "pred/summaries/stddev/Square"
  input: "pred/summaries/stddev/Const"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "pred/summaries/stddev/Sqrt"
  op: "Sqrt"
  input: "pred/summaries/stddev/Mean"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "pred/summaries/stddev_1/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "pred/summaries/stddev_1"
      }
    }
  }
}
node {
  name: "pred/summaries/stddev_1"
  op: "ScalarSummary"
  input: "pred/summaries/stddev_1/tags"
  input: "pred/summaries/stddev/Sqrt"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "pred/summaries/Const_1"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 2
          }
        }
        tensor_content: "\000\000\000\000\001\000\000\000"
      }
    }
  }
}
node {
  name: "pred/summaries/Max"
  op: "Max"
  input: "layer3/activation"
  input: "pred/summaries/Const_1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "pred/summaries/max/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "pred/summaries/max"
      }
    }
  }
}
node {
  name: "pred/summaries/max"
  op: "ScalarSummary"
  input: "pred/summaries/max/tags"
  input: "pred/summaries/Max"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "pred/summaries/Const_2"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 2
          }
        }
        tensor_content: "\000\000\000\000\001\000\000\000"
      }
    }
  }
}
node {
  name: "pred/summaries/Min"
  op: "Min"
  input: "layer3/activation"
  input: "pred/summaries/Const_2"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "pred/summaries/min/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "pred/summaries/min"
      }
    }
  }
}
node {
  name: "pred/summaries/min"
  op: "ScalarSummary"
  input: "pred/summaries/min/tags"
  input: "pred/summaries/Min"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "pred/summaries/histogram/tag"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "pred/summaries/histogram"
      }
    }
  }
}
node {
  name: "pred/summaries/histogram"
  op: "HistogramSummary"
  input: "pred/summaries/histogram/tag"
  input: "layer3/activation"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "loss/sub"
  op: "Sub"
  input: "label"
  input: "layer3/activation"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "loss/Square"
  op: "Square"
  input: "loss/sub"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "loss/Const"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 2
          }
        }
        tensor_content: "\000\000\000\000\001\000\000\000"
      }
    }
  }
}
node {
  name: "loss/Mean"
  op: "Mean"
  input: "loss/Square"
  input: "loss/Const"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "loss/loss/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "loss/loss"
      }
    }
  }
}
node {
  name: "loss/loss"
  op: "ScalarSummary"
  input: "loss/loss/tags"
  input: "loss/Mean"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "global_step/Initializer/Const"
  op: "Const"
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@global_step"
      }
    }
  }
  attr {
    key: "dtype"
    value {
      type: DT_INT64
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT64
        tensor_shape {
        }
        int64_val: 0
      }
    }
  }
}
node {
  name: "global_step"
  op: "VariableV2"
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@global_step"
      }
    }
  }
  attr {
    key: "container"
    value {
      s: ""
    }
  }
  attr {
    key: "dtype"
    value {
      type: DT_INT64
    }
  }
  attr {
    key: "shape"
    value {
      shape {
      }
    }
  }
  attr {
    key: "shared_name"
    value {
      s: ""
    }
  }
}
node {
  name: "global_step/Assign"
  op: "Assign"
  input: "global_step"
  input: "global_step/Initializer/Const"
  attr {
    key: "T"
    value {
      type: DT_INT64
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@global_step"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: true
    }
  }
  attr {
    key: "validate_shape"
    value {
      b: true
    }
  }
}
node {
  name: "global_step/read"
  op: "Identity"
  input: "global_step"
  attr {
    key: "T"
    value {
      type: DT_INT64
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@global_step"
      }
    }
  }
}
node {
  name: "learning_rate/ExponentialDecay/learning_rate"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
        }
        float_val: 0.10000000149
      }
    }
  }
}
node {
  name: "learning_rate/ExponentialDecay/Cast"
  op: "Cast"
  input: "global_step/read"
  attr {
    key: "DstT"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "SrcT"
    value {
      type: DT_INT64
    }
  }
}
node {
  name: "learning_rate/ExponentialDecay/Cast_1/x"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 500
      }
    }
  }
}
node {
  name: "learning_rate/ExponentialDecay/Cast_1"
  op: "Cast"
  input: "learning_rate/ExponentialDecay/Cast_1/x"
  attr {
    key: "DstT"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "SrcT"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "learning_rate/ExponentialDecay/Cast_2/x"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
        }
        float_val: 0.10000000149
      }
    }
  }
}
node {
  name: "learning_rate/ExponentialDecay/truediv"
  op: "RealDiv"
  input: "learning_rate/ExponentialDecay/Cast"
  input: "learning_rate/ExponentialDecay/Cast_1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "learning_rate/ExponentialDecay/Floor"
  op: "Floor"
  input: "learning_rate/ExponentialDecay/truediv"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "learning_rate/ExponentialDecay/Pow"
  op: "Pow"
  input: "learning_rate/ExponentialDecay/Cast_2/x"
  input: "learning_rate/ExponentialDecay/Floor"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "learning_rate/ExponentialDecay"
  op: "Mul"
  input: "learning_rate/ExponentialDecay/learning_rate"
  input: "learning_rate/ExponentialDecay/Pow"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "learning_rate/rate/tags"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "learning_rate/rate"
      }
    }
  }
}
node {
  name: "learning_rate/rate"
  op: "ScalarSummary"
  input: "learning_rate/rate/tags"
  input: "learning_rate/ExponentialDecay"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "Merge/MergeSummary"
  op: "MergeSummary"
  input: "input_producer/fraction_of_32_full"
  input: "input_producer_1/fraction_of_32_full"
  input: "shuffle/fraction_over_15000_of_3_full"
  input: "layer1/weights/summaries/mean"
  input: "layer1/weights/summaries/stddev_1"
  input: "layer1/weights/summaries/max"
  input: "layer1/weights/summaries/min"
  input: "layer1/weights/summaries/histogram"
  input: "layer1/biases/summaries/mean"
  input: "layer1/biases/summaries/stddev_1"
  input: "layer1/biases/summaries/max"
  input: "layer1/biases/summaries/min"
  input: "layer1/biases/summaries/histogram"
  input: "layer1/Wx_plus_b/pre_activations"
  input: "layer1/activations"
  input: "layer2/weights/summaries/mean"
  input: "layer2/weights/summaries/stddev_1"
  input: "layer2/weights/summaries/max"
  input: "layer2/weights/summaries/min"
  input: "layer2/weights/summaries/histogram"
  input: "layer2/biases/summaries/mean"
  input: "layer2/biases/summaries/stddev_1"
  input: "layer2/biases/summaries/max"
  input: "layer2/biases/summaries/min"
  input: "layer2/biases/summaries/histogram"
  input: "layer2/Wx_plus_b/pre_activations"
  input: "layer2/activations"
  input: "layer3/weights/summaries/mean"
  input: "layer3/weights/summaries/stddev_1"
  input: "layer3/weights/summaries/max"
  input: "layer3/weights/summaries/min"
  input: "layer3/weights/summaries/histogram"
  input: "layer3/biases/summaries/mean"
  input: "layer3/biases/summaries/stddev_1"
  input: "layer3/biases/summaries/max"
  input: "layer3/biases/summaries/min"
  input: "layer3/biases/summaries/histogram"
  input: "layer3/Wx_plus_b/pre_activations"
  input: "layer3/activations"
  input: "pred/summaries/mean"
  input: "pred/summaries/stddev_1"
  input: "pred/summaries/max"
  input: "pred/summaries/min"
  input: "pred/summaries/histogram"
  input: "loss/loss"
  input: "learning_rate/rate"
  attr {
    key: "N"
    value {
      i: 46
    }
  }
}
node {
  name: "save/Const"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
        }
        string_val: "model"
      }
    }
  }
}
node {
  name: "save/SaveV2/tensor_names"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
          dim {
            size: 7
          }
        }
        string_val: "global_step"
        string_val: "layer1/biases/Variable"
        string_val: "layer1/weights/Variable"
        string_val: "layer2/biases/Variable"
        string_val: "layer2/weights/Variable"
        string_val: "layer3/biases/Variable"
        string_val: "layer3/weights/Variable"
      }
    }
  }
}
node {
  name: "save/SaveV2/shape_and_slices"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
          dim {
            size: 7
          }
        }
        string_val: ""
        string_val: ""
        string_val: ""
        string_val: ""
        string_val: ""
        string_val: ""
        string_val: ""
      }
    }
  }
}
node {
  name: "save/SaveV2"
  op: "SaveV2"
  input: "save/Const"
  input: "save/SaveV2/tensor_names"
  input: "save/SaveV2/shape_and_slices"
  input: "global_step"
  input: "layer1/biases/Variable"
  input: "layer1/weights/Variable"
  input: "layer2/biases/Variable"
  input: "layer2/weights/Variable"
  input: "layer3/biases/Variable"
  input: "layer3/weights/Variable"
  attr {
    key: "dtypes"
    value {
      list {
        type: DT_INT64
        type: DT_FLOAT
        type: DT_FLOAT
        type: DT_FLOAT
        type: DT_FLOAT
        type: DT_FLOAT
        type: DT_FLOAT
      }
    }
  }
}
node {
  name: "save/control_dependency"
  op: "Identity"
  input: "save/Const"
  input: "^save/SaveV2"
  attr {
    key: "T"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@save/Const"
      }
    }
  }
}
node {
  name: "save/RestoreV2/tensor_names"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
          dim {
            size: 1
          }
        }
        string_val: "global_step"
      }
    }
  }
}
node {
  name: "save/RestoreV2/shape_and_slices"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
          dim {
            size: 1
          }
        }
        string_val: ""
      }
    }
  }
}
node {
  name: "save/RestoreV2"
  op: "RestoreV2"
  input: "save/Const"
  input: "save/RestoreV2/tensor_names"
  input: "save/RestoreV2/shape_and_slices"
  attr {
    key: "dtypes"
    value {
      list {
        type: DT_INT64
      }
    }
  }
}
node {
  name: "save/Assign"
  op: "Assign"
  input: "global_step"
  input: "save/RestoreV2"
  attr {
    key: "T"
    value {
      type: DT_INT64
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@global_step"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: true
    }
  }
  attr {
    key: "validate_shape"
    value {
      b: true
    }
  }
}
node {
  name: "save/RestoreV2_1/tensor_names"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
          dim {
            size: 1
          }
        }
        string_val: "layer1/biases/Variable"
      }
    }
  }
}
node {
  name: "save/RestoreV2_1/shape_and_slices"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
          dim {
            size: 1
          }
        }
        string_val: ""
      }
    }
  }
}
node {
  name: "save/RestoreV2_1"
  op: "RestoreV2"
  input: "save/Const"
  input: "save/RestoreV2_1/tensor_names"
  input: "save/RestoreV2_1/shape_and_slices"
  attr {
    key: "dtypes"
    value {
      list {
        type: DT_FLOAT
      }
    }
  }
}
node {
  name: "save/Assign_1"
  op: "Assign"
  input: "layer1/biases/Variable"
  input: "save/RestoreV2_1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer1/biases/Variable"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: true
    }
  }
  attr {
    key: "validate_shape"
    value {
      b: true
    }
  }
}
node {
  name: "save/RestoreV2_2/tensor_names"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
          dim {
            size: 1
          }
        }
        string_val: "layer1/weights/Variable"
      }
    }
  }
}
node {
  name: "save/RestoreV2_2/shape_and_slices"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
          dim {
            size: 1
          }
        }
        string_val: ""
      }
    }
  }
}
node {
  name: "save/RestoreV2_2"
  op: "RestoreV2"
  input: "save/Const"
  input: "save/RestoreV2_2/tensor_names"
  input: "save/RestoreV2_2/shape_and_slices"
  attr {
    key: "dtypes"
    value {
      list {
        type: DT_FLOAT
      }
    }
  }
}
node {
  name: "save/Assign_2"
  op: "Assign"
  input: "layer1/weights/Variable"
  input: "save/RestoreV2_2"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer1/weights/Variable"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: true
    }
  }
  attr {
    key: "validate_shape"
    value {
      b: true
    }
  }
}
node {
  name: "save/RestoreV2_3/tensor_names"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
          dim {
            size: 1
          }
        }
        string_val: "layer2/biases/Variable"
      }
    }
  }
}
node {
  name: "save/RestoreV2_3/shape_and_slices"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
          dim {
            size: 1
          }
        }
        string_val: ""
      }
    }
  }
}
node {
  name: "save/RestoreV2_3"
  op: "RestoreV2"
  input: "save/Const"
  input: "save/RestoreV2_3/tensor_names"
  input: "save/RestoreV2_3/shape_and_slices"
  attr {
    key: "dtypes"
    value {
      list {
        type: DT_FLOAT
      }
    }
  }
}
node {
  name: "save/Assign_3"
  op: "Assign"
  input: "layer2/biases/Variable"
  input: "save/RestoreV2_3"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer2/biases/Variable"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: true
    }
  }
  attr {
    key: "validate_shape"
    value {
      b: true
    }
  }
}
node {
  name: "save/RestoreV2_4/tensor_names"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
          dim {
            size: 1
          }
        }
        string_val: "layer2/weights/Variable"
      }
    }
  }
}
node {
  name: "save/RestoreV2_4/shape_and_slices"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
          dim {
            size: 1
          }
        }
        string_val: ""
      }
    }
  }
}
node {
  name: "save/RestoreV2_4"
  op: "RestoreV2"
  input: "save/Const"
  input: "save/RestoreV2_4/tensor_names"
  input: "save/RestoreV2_4/shape_and_slices"
  attr {
    key: "dtypes"
    value {
      list {
        type: DT_FLOAT
      }
    }
  }
}
node {
  name: "save/Assign_4"
  op: "Assign"
  input: "layer2/weights/Variable"
  input: "save/RestoreV2_4"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer2/weights/Variable"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: true
    }
  }
  attr {
    key: "validate_shape"
    value {
      b: true
    }
  }
}
node {
  name: "save/RestoreV2_5/tensor_names"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
          dim {
            size: 1
          }
        }
        string_val: "layer3/biases/Variable"
      }
    }
  }
}
node {
  name: "save/RestoreV2_5/shape_and_slices"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
          dim {
            size: 1
          }
        }
        string_val: ""
      }
    }
  }
}
node {
  name: "save/RestoreV2_5"
  op: "RestoreV2"
  input: "save/Const"
  input: "save/RestoreV2_5/tensor_names"
  input: "save/RestoreV2_5/shape_and_slices"
  attr {
    key: "dtypes"
    value {
      list {
        type: DT_FLOAT
      }
    }
  }
}
node {
  name: "save/Assign_5"
  op: "Assign"
  input: "layer3/biases/Variable"
  input: "save/RestoreV2_5"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer3/biases/Variable"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: true
    }
  }
  attr {
    key: "validate_shape"
    value {
      b: true
    }
  }
}
node {
  name: "save/RestoreV2_6/tensor_names"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
          dim {
            size: 1
          }
        }
        string_val: "layer3/weights/Variable"
      }
    }
  }
}
node {
  name: "save/RestoreV2_6/shape_and_slices"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_STRING
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_STRING
        tensor_shape {
          dim {
            size: 1
          }
        }
        string_val: ""
      }
    }
  }
}
node {
  name: "save/RestoreV2_6"
  op: "RestoreV2"
  input: "save/Const"
  input: "save/RestoreV2_6/tensor_names"
  input: "save/RestoreV2_6/shape_and_slices"
  attr {
    key: "dtypes"
    value {
      list {
        type: DT_FLOAT
      }
    }
  }
}
node {
  name: "save/Assign_6"
  op: "Assign"
  input: "layer3/weights/Variable"
  input: "save/RestoreV2_6"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer3/weights/Variable"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: true
    }
  }
  attr {
    key: "validate_shape"
    value {
      b: true
    }
  }
}
node {
  name: "save/restore_all"
  op: "NoOp"
  input: "^save/Assign"
  input: "^save/Assign_1"
  input: "^save/Assign_2"
  input: "^save/Assign_3"
  input: "^save/Assign_4"
  input: "^save/Assign_5"
  input: "^save/Assign_6"
}
node {
  name: "gradients/Shape"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
          }
        }
      }
    }
  }
}
node {
  name: "gradients/Const"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
        }
        float_val: 1.0
      }
    }
  }
}
node {
  name: "gradients/Fill"
  op: "Fill"
  input: "gradients/Shape"
  input: "gradients/Const"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "gradients/loss/Mean_grad/Reshape/shape"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 2
          }
        }
        tensor_content: "\001\000\000\000\001\000\000\000"
      }
    }
  }
}
node {
  name: "gradients/loss/Mean_grad/Reshape"
  op: "Reshape"
  input: "gradients/Fill"
  input: "gradients/loss/Mean_grad/Reshape/shape"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tshape"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "gradients/loss/Mean_grad/Tile/multiples"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 2
          }
        }
        tensor_content: "\001\000\000\000\003\000\000\000"
      }
    }
  }
}
node {
  name: "gradients/loss/Mean_grad/Tile"
  op: "Tile"
  input: "gradients/loss/Mean_grad/Reshape"
  input: "gradients/loss/Mean_grad/Tile/multiples"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tmultiples"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "gradients/loss/Mean_grad/Shape"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 2
          }
        }
        tensor_content: "\001\000\000\000\003\000\000\000"
      }
    }
  }
}
node {
  name: "gradients/loss/Mean_grad/Shape_1"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
          }
        }
      }
    }
  }
}
node {
  name: "gradients/loss/Mean_grad/Const"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 1
          }
        }
        int_val: 0
      }
    }
  }
}
node {
  name: "gradients/loss/Mean_grad/Prod"
  op: "Prod"
  input: "gradients/loss/Mean_grad/Shape"
  input: "gradients/loss/Mean_grad/Const"
  attr {
    key: "T"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "gradients/loss/Mean_grad/Const_1"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 1
          }
        }
        int_val: 0
      }
    }
  }
}
node {
  name: "gradients/loss/Mean_grad/Prod_1"
  op: "Prod"
  input: "gradients/loss/Mean_grad/Shape_1"
  input: "gradients/loss/Mean_grad/Const_1"
  attr {
    key: "T"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "gradients/loss/Mean_grad/Maximum/y"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
        }
        int_val: 1
      }
    }
  }
}
node {
  name: "gradients/loss/Mean_grad/Maximum"
  op: "Maximum"
  input: "gradients/loss/Mean_grad/Prod_1"
  input: "gradients/loss/Mean_grad/Maximum/y"
  attr {
    key: "T"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "gradients/loss/Mean_grad/floordiv"
  op: "FloorDiv"
  input: "gradients/loss/Mean_grad/Prod"
  input: "gradients/loss/Mean_grad/Maximum"
  attr {
    key: "T"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "gradients/loss/Mean_grad/Cast"
  op: "Cast"
  input: "gradients/loss/Mean_grad/floordiv"
  attr {
    key: "DstT"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "SrcT"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "gradients/loss/Mean_grad/truediv"
  op: "RealDiv"
  input: "gradients/loss/Mean_grad/Tile"
  input: "gradients/loss/Mean_grad/Cast"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "gradients/loss/Square_grad/mul/x"
  op: "Const"
  input: "^gradients/loss/Mean_grad/truediv"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
        }
        float_val: 2.0
      }
    }
  }
}
node {
  name: "gradients/loss/Square_grad/mul"
  op: "Mul"
  input: "gradients/loss/Square_grad/mul/x"
  input: "loss/sub"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "gradients/loss/Square_grad/mul_1"
  op: "Mul"
  input: "gradients/loss/Mean_grad/truediv"
  input: "gradients/loss/Square_grad/mul"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "gradients/loss/sub_grad/Shape"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 2
          }
        }
        tensor_content: "\001\000\000\000\003\000\000\000"
      }
    }
  }
}
node {
  name: "gradients/loss/sub_grad/Shape_1"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 2
          }
        }
        tensor_content: "\001\000\000\000\003\000\000\000"
      }
    }
  }
}
node {
  name: "gradients/loss/sub_grad/BroadcastGradientArgs"
  op: "BroadcastGradientArgs"
  input: "gradients/loss/sub_grad/Shape"
  input: "gradients/loss/sub_grad/Shape_1"
  attr {
    key: "T"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "gradients/loss/sub_grad/Sum"
  op: "Sum"
  input: "gradients/loss/Square_grad/mul_1"
  input: "gradients/loss/sub_grad/BroadcastGradientArgs"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "gradients/loss/sub_grad/Reshape"
  op: "Reshape"
  input: "gradients/loss/sub_grad/Sum"
  input: "gradients/loss/sub_grad/Shape"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tshape"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "gradients/loss/sub_grad/Sum_1"
  op: "Sum"
  input: "gradients/loss/Square_grad/mul_1"
  input: "gradients/loss/sub_grad/BroadcastGradientArgs:1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "gradients/loss/sub_grad/Neg"
  op: "Neg"
  input: "gradients/loss/sub_grad/Sum_1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "gradients/loss/sub_grad/Reshape_1"
  op: "Reshape"
  input: "gradients/loss/sub_grad/Neg"
  input: "gradients/loss/sub_grad/Shape_1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tshape"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "gradients/loss/sub_grad/tuple/group_deps"
  op: "NoOp"
  input: "^gradients/loss/sub_grad/Reshape"
  input: "^gradients/loss/sub_grad/Reshape_1"
}
node {
  name: "gradients/loss/sub_grad/tuple/control_dependency"
  op: "Identity"
  input: "gradients/loss/sub_grad/Reshape"
  input: "^gradients/loss/sub_grad/tuple/group_deps"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@gradients/loss/sub_grad/Reshape"
      }
    }
  }
}
node {
  name: "gradients/loss/sub_grad/tuple/control_dependency_1"
  op: "Identity"
  input: "gradients/loss/sub_grad/Reshape_1"
  input: "^gradients/loss/sub_grad/tuple/group_deps"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@gradients/loss/sub_grad/Reshape_1"
      }
    }
  }
}
node {
  name: "gradients/layer3/Wx_plus_b/add_grad/Shape"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 2
          }
        }
        tensor_content: "\001\000\000\000\003\000\000\000"
      }
    }
  }
}
node {
  name: "gradients/layer3/Wx_plus_b/add_grad/Shape_1"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 1
          }
        }
        int_val: 3
      }
    }
  }
}
node {
  name: "gradients/layer3/Wx_plus_b/add_grad/BroadcastGradientArgs"
  op: "BroadcastGradientArgs"
  input: "gradients/layer3/Wx_plus_b/add_grad/Shape"
  input: "gradients/layer3/Wx_plus_b/add_grad/Shape_1"
  attr {
    key: "T"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "gradients/layer3/Wx_plus_b/add_grad/Sum"
  op: "Sum"
  input: "gradients/loss/sub_grad/tuple/control_dependency_1"
  input: "gradients/layer3/Wx_plus_b/add_grad/BroadcastGradientArgs"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "gradients/layer3/Wx_plus_b/add_grad/Reshape"
  op: "Reshape"
  input: "gradients/layer3/Wx_plus_b/add_grad/Sum"
  input: "gradients/layer3/Wx_plus_b/add_grad/Shape"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tshape"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "gradients/layer3/Wx_plus_b/add_grad/Sum_1"
  op: "Sum"
  input: "gradients/loss/sub_grad/tuple/control_dependency_1"
  input: "gradients/layer3/Wx_plus_b/add_grad/BroadcastGradientArgs:1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "gradients/layer3/Wx_plus_b/add_grad/Reshape_1"
  op: "Reshape"
  input: "gradients/layer3/Wx_plus_b/add_grad/Sum_1"
  input: "gradients/layer3/Wx_plus_b/add_grad/Shape_1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tshape"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "gradients/layer3/Wx_plus_b/add_grad/tuple/group_deps"
  op: "NoOp"
  input: "^gradients/layer3/Wx_plus_b/add_grad/Reshape"
  input: "^gradients/layer3/Wx_plus_b/add_grad/Reshape_1"
}
node {
  name: "gradients/layer3/Wx_plus_b/add_grad/tuple/control_dependency"
  op: "Identity"
  input: "gradients/layer3/Wx_plus_b/add_grad/Reshape"
  input: "^gradients/layer3/Wx_plus_b/add_grad/tuple/group_deps"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@gradients/layer3/Wx_plus_b/add_grad/Reshape"
      }
    }
  }
}
node {
  name: "gradients/layer3/Wx_plus_b/add_grad/tuple/control_dependency_1"
  op: "Identity"
  input: "gradients/layer3/Wx_plus_b/add_grad/Reshape_1"
  input: "^gradients/layer3/Wx_plus_b/add_grad/tuple/group_deps"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@gradients/layer3/Wx_plus_b/add_grad/Reshape_1"
      }
    }
  }
}
node {
  name: "gradients/layer3/Wx_plus_b/MatMul_grad/MatMul"
  op: "MatMul"
  input: "gradients/layer3/Wx_plus_b/add_grad/tuple/control_dependency"
  input: "layer3/weights/Variable/read"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "transpose_a"
    value {
      b: false
    }
  }
  attr {
    key: "transpose_b"
    value {
      b: true
    }
  }
}
node {
  name: "gradients/layer3/Wx_plus_b/MatMul_grad/MatMul_1"
  op: "MatMul"
  input: "input_2"
  input: "gradients/layer3/Wx_plus_b/add_grad/tuple/control_dependency"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "transpose_a"
    value {
      b: true
    }
  }
  attr {
    key: "transpose_b"
    value {
      b: false
    }
  }
}
node {
  name: "gradients/layer3/Wx_plus_b/MatMul_grad/tuple/group_deps"
  op: "NoOp"
  input: "^gradients/layer3/Wx_plus_b/MatMul_grad/MatMul"
  input: "^gradients/layer3/Wx_plus_b/MatMul_grad/MatMul_1"
}
node {
  name: "gradients/layer3/Wx_plus_b/MatMul_grad/tuple/control_dependency"
  op: "Identity"
  input: "gradients/layer3/Wx_plus_b/MatMul_grad/MatMul"
  input: "^gradients/layer3/Wx_plus_b/MatMul_grad/tuple/group_deps"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@gradients/layer3/Wx_plus_b/MatMul_grad/MatMul"
      }
    }
  }
}
node {
  name: "gradients/layer3/Wx_plus_b/MatMul_grad/tuple/control_dependency_1"
  op: "Identity"
  input: "gradients/layer3/Wx_plus_b/MatMul_grad/MatMul_1"
  input: "^gradients/layer3/Wx_plus_b/MatMul_grad/tuple/group_deps"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@gradients/layer3/Wx_plus_b/MatMul_grad/MatMul_1"
      }
    }
  }
}
node {
  name: "gradients/input_2_grad/Shape"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 2
          }
        }
        tensor_content: "\001\000\000\000\n\000\000\000"
      }
    }
  }
}
node {
  name: "gradients/input_2_grad/Reshape"
  op: "Reshape"
  input: "gradients/layer3/Wx_plus_b/MatMul_grad/tuple/control_dependency"
  input: "gradients/input_2_grad/Shape"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tshape"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "gradients/layer2/activation_grad/ReluGrad"
  op: "ReluGrad"
  input: "gradients/input_2_grad/Reshape"
  input: "layer2/activation"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "gradients/layer2/Wx_plus_b/add_grad/Shape"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 2
          }
        }
        tensor_content: "\001\000\000\000\n\000\000\000"
      }
    }
  }
}
node {
  name: "gradients/layer2/Wx_plus_b/add_grad/Shape_1"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 1
          }
        }
        int_val: 10
      }
    }
  }
}
node {
  name: "gradients/layer2/Wx_plus_b/add_grad/BroadcastGradientArgs"
  op: "BroadcastGradientArgs"
  input: "gradients/layer2/Wx_plus_b/add_grad/Shape"
  input: "gradients/layer2/Wx_plus_b/add_grad/Shape_1"
  attr {
    key: "T"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "gradients/layer2/Wx_plus_b/add_grad/Sum"
  op: "Sum"
  input: "gradients/layer2/activation_grad/ReluGrad"
  input: "gradients/layer2/Wx_plus_b/add_grad/BroadcastGradientArgs"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "gradients/layer2/Wx_plus_b/add_grad/Reshape"
  op: "Reshape"
  input: "gradients/layer2/Wx_plus_b/add_grad/Sum"
  input: "gradients/layer2/Wx_plus_b/add_grad/Shape"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tshape"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "gradients/layer2/Wx_plus_b/add_grad/Sum_1"
  op: "Sum"
  input: "gradients/layer2/activation_grad/ReluGrad"
  input: "gradients/layer2/Wx_plus_b/add_grad/BroadcastGradientArgs:1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "gradients/layer2/Wx_plus_b/add_grad/Reshape_1"
  op: "Reshape"
  input: "gradients/layer2/Wx_plus_b/add_grad/Sum_1"
  input: "gradients/layer2/Wx_plus_b/add_grad/Shape_1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tshape"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "gradients/layer2/Wx_plus_b/add_grad/tuple/group_deps"
  op: "NoOp"
  input: "^gradients/layer2/Wx_plus_b/add_grad/Reshape"
  input: "^gradients/layer2/Wx_plus_b/add_grad/Reshape_1"
}
node {
  name: "gradients/layer2/Wx_plus_b/add_grad/tuple/control_dependency"
  op: "Identity"
  input: "gradients/layer2/Wx_plus_b/add_grad/Reshape"
  input: "^gradients/layer2/Wx_plus_b/add_grad/tuple/group_deps"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@gradients/layer2/Wx_plus_b/add_grad/Reshape"
      }
    }
  }
}
node {
  name: "gradients/layer2/Wx_plus_b/add_grad/tuple/control_dependency_1"
  op: "Identity"
  input: "gradients/layer2/Wx_plus_b/add_grad/Reshape_1"
  input: "^gradients/layer2/Wx_plus_b/add_grad/tuple/group_deps"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@gradients/layer2/Wx_plus_b/add_grad/Reshape_1"
      }
    }
  }
}
node {
  name: "gradients/layer2/Wx_plus_b/MatMul_grad/MatMul"
  op: "MatMul"
  input: "gradients/layer2/Wx_plus_b/add_grad/tuple/control_dependency"
  input: "layer2/weights/Variable/read"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "transpose_a"
    value {
      b: false
    }
  }
  attr {
    key: "transpose_b"
    value {
      b: true
    }
  }
}
node {
  name: "gradients/layer2/Wx_plus_b/MatMul_grad/MatMul_1"
  op: "MatMul"
  input: "input_1"
  input: "gradients/layer2/Wx_plus_b/add_grad/tuple/control_dependency"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "transpose_a"
    value {
      b: true
    }
  }
  attr {
    key: "transpose_b"
    value {
      b: false
    }
  }
}
node {
  name: "gradients/layer2/Wx_plus_b/MatMul_grad/tuple/group_deps"
  op: "NoOp"
  input: "^gradients/layer2/Wx_plus_b/MatMul_grad/MatMul"
  input: "^gradients/layer2/Wx_plus_b/MatMul_grad/MatMul_1"
}
node {
  name: "gradients/layer2/Wx_plus_b/MatMul_grad/tuple/control_dependency"
  op: "Identity"
  input: "gradients/layer2/Wx_plus_b/MatMul_grad/MatMul"
  input: "^gradients/layer2/Wx_plus_b/MatMul_grad/tuple/group_deps"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@gradients/layer2/Wx_plus_b/MatMul_grad/MatMul"
      }
    }
  }
}
node {
  name: "gradients/layer2/Wx_plus_b/MatMul_grad/tuple/control_dependency_1"
  op: "Identity"
  input: "gradients/layer2/Wx_plus_b/MatMul_grad/MatMul_1"
  input: "^gradients/layer2/Wx_plus_b/MatMul_grad/tuple/group_deps"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@gradients/layer2/Wx_plus_b/MatMul_grad/MatMul_1"
      }
    }
  }
}
node {
  name: "gradients/input_1_grad/Shape"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 2
          }
        }
        tensor_content: "\001\000\000\000\n\000\000\000"
      }
    }
  }
}
node {
  name: "gradients/input_1_grad/Reshape"
  op: "Reshape"
  input: "gradients/layer2/Wx_plus_b/MatMul_grad/tuple/control_dependency"
  input: "gradients/input_1_grad/Shape"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tshape"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "gradients/layer1/activation_grad/ReluGrad"
  op: "ReluGrad"
  input: "gradients/input_1_grad/Reshape"
  input: "layer1/activation"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
}
node {
  name: "gradients/layer1/Wx_plus_b/add_grad/Shape"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 2
          }
        }
        tensor_content: "\001\000\000\000\n\000\000\000"
      }
    }
  }
}
node {
  name: "gradients/layer1/Wx_plus_b/add_grad/Shape_1"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT32
        tensor_shape {
          dim {
            size: 1
          }
        }
        int_val: 10
      }
    }
  }
}
node {
  name: "gradients/layer1/Wx_plus_b/add_grad/BroadcastGradientArgs"
  op: "BroadcastGradientArgs"
  input: "gradients/layer1/Wx_plus_b/add_grad/Shape"
  input: "gradients/layer1/Wx_plus_b/add_grad/Shape_1"
  attr {
    key: "T"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "gradients/layer1/Wx_plus_b/add_grad/Sum"
  op: "Sum"
  input: "gradients/layer1/activation_grad/ReluGrad"
  input: "gradients/layer1/Wx_plus_b/add_grad/BroadcastGradientArgs"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "gradients/layer1/Wx_plus_b/add_grad/Reshape"
  op: "Reshape"
  input: "gradients/layer1/Wx_plus_b/add_grad/Sum"
  input: "gradients/layer1/Wx_plus_b/add_grad/Shape"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tshape"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "gradients/layer1/Wx_plus_b/add_grad/Sum_1"
  op: "Sum"
  input: "gradients/layer1/activation_grad/ReluGrad"
  input: "gradients/layer1/Wx_plus_b/add_grad/BroadcastGradientArgs:1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tidx"
    value {
      type: DT_INT32
    }
  }
  attr {
    key: "keep_dims"
    value {
      b: false
    }
  }
}
node {
  name: "gradients/layer1/Wx_plus_b/add_grad/Reshape_1"
  op: "Reshape"
  input: "gradients/layer1/Wx_plus_b/add_grad/Sum_1"
  input: "gradients/layer1/Wx_plus_b/add_grad/Shape_1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "Tshape"
    value {
      type: DT_INT32
    }
  }
}
node {
  name: "gradients/layer1/Wx_plus_b/add_grad/tuple/group_deps"
  op: "NoOp"
  input: "^gradients/layer1/Wx_plus_b/add_grad/Reshape"
  input: "^gradients/layer1/Wx_plus_b/add_grad/Reshape_1"
}
node {
  name: "gradients/layer1/Wx_plus_b/add_grad/tuple/control_dependency"
  op: "Identity"
  input: "gradients/layer1/Wx_plus_b/add_grad/Reshape"
  input: "^gradients/layer1/Wx_plus_b/add_grad/tuple/group_deps"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@gradients/layer1/Wx_plus_b/add_grad/Reshape"
      }
    }
  }
}
node {
  name: "gradients/layer1/Wx_plus_b/add_grad/tuple/control_dependency_1"
  op: "Identity"
  input: "gradients/layer1/Wx_plus_b/add_grad/Reshape_1"
  input: "^gradients/layer1/Wx_plus_b/add_grad/tuple/group_deps"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@gradients/layer1/Wx_plus_b/add_grad/Reshape_1"
      }
    }
  }
}
node {
  name: "gradients/layer1/Wx_plus_b/MatMul_grad/MatMul"
  op: "MatMul"
  input: "gradients/layer1/Wx_plus_b/add_grad/tuple/control_dependency"
  input: "layer1/weights/Variable/read"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "transpose_a"
    value {
      b: false
    }
  }
  attr {
    key: "transpose_b"
    value {
      b: true
    }
  }
}
node {
  name: "gradients/layer1/Wx_plus_b/MatMul_grad/MatMul_1"
  op: "MatMul"
  input: "input"
  input: "gradients/layer1/Wx_plus_b/add_grad/tuple/control_dependency"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "transpose_a"
    value {
      b: true
    }
  }
  attr {
    key: "transpose_b"
    value {
      b: false
    }
  }
}
node {
  name: "gradients/layer1/Wx_plus_b/MatMul_grad/tuple/group_deps"
  op: "NoOp"
  input: "^gradients/layer1/Wx_plus_b/MatMul_grad/MatMul"
  input: "^gradients/layer1/Wx_plus_b/MatMul_grad/MatMul_1"
}
node {
  name: "gradients/layer1/Wx_plus_b/MatMul_grad/tuple/control_dependency"
  op: "Identity"
  input: "gradients/layer1/Wx_plus_b/MatMul_grad/MatMul"
  input: "^gradients/layer1/Wx_plus_b/MatMul_grad/tuple/group_deps"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@gradients/layer1/Wx_plus_b/MatMul_grad/MatMul"
      }
    }
  }
}
node {
  name: "gradients/layer1/Wx_plus_b/MatMul_grad/tuple/control_dependency_1"
  op: "Identity"
  input: "gradients/layer1/Wx_plus_b/MatMul_grad/MatMul_1"
  input: "^gradients/layer1/Wx_plus_b/MatMul_grad/tuple/group_deps"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@gradients/layer1/Wx_plus_b/MatMul_grad/MatMul_1"
      }
    }
  }
}
node {
  name: "zeros"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
          dim {
            size: 6
          }
          dim {
            size: 10
          }
        }
        float_val: 0.0
      }
    }
  }
}
node {
  name: "layer1/weights/Variable/Adadelta"
  op: "VariableV2"
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer1/weights/Variable"
      }
    }
  }
  attr {
    key: "container"
    value {
      s: ""
    }
  }
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "shape"
    value {
      shape {
        dim {
          size: 6
        }
        dim {
          size: 10
        }
      }
    }
  }
  attr {
    key: "shared_name"
    value {
      s: ""
    }
  }
}
node {
  name: "layer1/weights/Variable/Adadelta/Assign"
  op: "Assign"
  input: "layer1/weights/Variable/Adadelta"
  input: "zeros"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer1/weights/Variable"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: true
    }
  }
  attr {
    key: "validate_shape"
    value {
      b: true
    }
  }
}
node {
  name: "layer1/weights/Variable/Adadelta/read"
  op: "Identity"
  input: "layer1/weights/Variable/Adadelta"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer1/weights/Variable"
      }
    }
  }
}
node {
  name: "zeros_1"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
          dim {
            size: 6
          }
          dim {
            size: 10
          }
        }
        float_val: 0.0
      }
    }
  }
}
node {
  name: "layer1/weights/Variable/Adadelta_1"
  op: "VariableV2"
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer1/weights/Variable"
      }
    }
  }
  attr {
    key: "container"
    value {
      s: ""
    }
  }
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "shape"
    value {
      shape {
        dim {
          size: 6
        }
        dim {
          size: 10
        }
      }
    }
  }
  attr {
    key: "shared_name"
    value {
      s: ""
    }
  }
}
node {
  name: "layer1/weights/Variable/Adadelta_1/Assign"
  op: "Assign"
  input: "layer1/weights/Variable/Adadelta_1"
  input: "zeros_1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer1/weights/Variable"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: true
    }
  }
  attr {
    key: "validate_shape"
    value {
      b: true
    }
  }
}
node {
  name: "layer1/weights/Variable/Adadelta_1/read"
  op: "Identity"
  input: "layer1/weights/Variable/Adadelta_1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer1/weights/Variable"
      }
    }
  }
}
node {
  name: "zeros_2"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
          dim {
            size: 10
          }
        }
        float_val: 0.0
      }
    }
  }
}
node {
  name: "layer1/biases/Variable/Adadelta"
  op: "VariableV2"
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer1/biases/Variable"
      }
    }
  }
  attr {
    key: "container"
    value {
      s: ""
    }
  }
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "shape"
    value {
      shape {
        dim {
          size: 10
        }
      }
    }
  }
  attr {
    key: "shared_name"
    value {
      s: ""
    }
  }
}
node {
  name: "layer1/biases/Variable/Adadelta/Assign"
  op: "Assign"
  input: "layer1/biases/Variable/Adadelta"
  input: "zeros_2"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer1/biases/Variable"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: true
    }
  }
  attr {
    key: "validate_shape"
    value {
      b: true
    }
  }
}
node {
  name: "layer1/biases/Variable/Adadelta/read"
  op: "Identity"
  input: "layer1/biases/Variable/Adadelta"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer1/biases/Variable"
      }
    }
  }
}
node {
  name: "zeros_3"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
          dim {
            size: 10
          }
        }
        float_val: 0.0
      }
    }
  }
}
node {
  name: "layer1/biases/Variable/Adadelta_1"
  op: "VariableV2"
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer1/biases/Variable"
      }
    }
  }
  attr {
    key: "container"
    value {
      s: ""
    }
  }
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "shape"
    value {
      shape {
        dim {
          size: 10
        }
      }
    }
  }
  attr {
    key: "shared_name"
    value {
      s: ""
    }
  }
}
node {
  name: "layer1/biases/Variable/Adadelta_1/Assign"
  op: "Assign"
  input: "layer1/biases/Variable/Adadelta_1"
  input: "zeros_3"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer1/biases/Variable"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: true
    }
  }
  attr {
    key: "validate_shape"
    value {
      b: true
    }
  }
}
node {
  name: "layer1/biases/Variable/Adadelta_1/read"
  op: "Identity"
  input: "layer1/biases/Variable/Adadelta_1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer1/biases/Variable"
      }
    }
  }
}
node {
  name: "zeros_4"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
          dim {
            size: 10
          }
          dim {
            size: 10
          }
        }
        float_val: 0.0
      }
    }
  }
}
node {
  name: "layer2/weights/Variable/Adadelta"
  op: "VariableV2"
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer2/weights/Variable"
      }
    }
  }
  attr {
    key: "container"
    value {
      s: ""
    }
  }
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "shape"
    value {
      shape {
        dim {
          size: 10
        }
        dim {
          size: 10
        }
      }
    }
  }
  attr {
    key: "shared_name"
    value {
      s: ""
    }
  }
}
node {
  name: "layer2/weights/Variable/Adadelta/Assign"
  op: "Assign"
  input: "layer2/weights/Variable/Adadelta"
  input: "zeros_4"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer2/weights/Variable"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: true
    }
  }
  attr {
    key: "validate_shape"
    value {
      b: true
    }
  }
}
node {
  name: "layer2/weights/Variable/Adadelta/read"
  op: "Identity"
  input: "layer2/weights/Variable/Adadelta"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer2/weights/Variable"
      }
    }
  }
}
node {
  name: "zeros_5"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
          dim {
            size: 10
          }
          dim {
            size: 10
          }
        }
        float_val: 0.0
      }
    }
  }
}
node {
  name: "layer2/weights/Variable/Adadelta_1"
  op: "VariableV2"
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer2/weights/Variable"
      }
    }
  }
  attr {
    key: "container"
    value {
      s: ""
    }
  }
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "shape"
    value {
      shape {
        dim {
          size: 10
        }
        dim {
          size: 10
        }
      }
    }
  }
  attr {
    key: "shared_name"
    value {
      s: ""
    }
  }
}
node {
  name: "layer2/weights/Variable/Adadelta_1/Assign"
  op: "Assign"
  input: "layer2/weights/Variable/Adadelta_1"
  input: "zeros_5"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer2/weights/Variable"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: true
    }
  }
  attr {
    key: "validate_shape"
    value {
      b: true
    }
  }
}
node {
  name: "layer2/weights/Variable/Adadelta_1/read"
  op: "Identity"
  input: "layer2/weights/Variable/Adadelta_1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer2/weights/Variable"
      }
    }
  }
}
node {
  name: "zeros_6"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
          dim {
            size: 10
          }
        }
        float_val: 0.0
      }
    }
  }
}
node {
  name: "layer2/biases/Variable/Adadelta"
  op: "VariableV2"
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer2/biases/Variable"
      }
    }
  }
  attr {
    key: "container"
    value {
      s: ""
    }
  }
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "shape"
    value {
      shape {
        dim {
          size: 10
        }
      }
    }
  }
  attr {
    key: "shared_name"
    value {
      s: ""
    }
  }
}
node {
  name: "layer2/biases/Variable/Adadelta/Assign"
  op: "Assign"
  input: "layer2/biases/Variable/Adadelta"
  input: "zeros_6"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer2/biases/Variable"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: true
    }
  }
  attr {
    key: "validate_shape"
    value {
      b: true
    }
  }
}
node {
  name: "layer2/biases/Variable/Adadelta/read"
  op: "Identity"
  input: "layer2/biases/Variable/Adadelta"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer2/biases/Variable"
      }
    }
  }
}
node {
  name: "zeros_7"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
          dim {
            size: 10
          }
        }
        float_val: 0.0
      }
    }
  }
}
node {
  name: "layer2/biases/Variable/Adadelta_1"
  op: "VariableV2"
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer2/biases/Variable"
      }
    }
  }
  attr {
    key: "container"
    value {
      s: ""
    }
  }
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "shape"
    value {
      shape {
        dim {
          size: 10
        }
      }
    }
  }
  attr {
    key: "shared_name"
    value {
      s: ""
    }
  }
}
node {
  name: "layer2/biases/Variable/Adadelta_1/Assign"
  op: "Assign"
  input: "layer2/biases/Variable/Adadelta_1"
  input: "zeros_7"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer2/biases/Variable"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: true
    }
  }
  attr {
    key: "validate_shape"
    value {
      b: true
    }
  }
}
node {
  name: "layer2/biases/Variable/Adadelta_1/read"
  op: "Identity"
  input: "layer2/biases/Variable/Adadelta_1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer2/biases/Variable"
      }
    }
  }
}
node {
  name: "zeros_8"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
          dim {
            size: 10
          }
          dim {
            size: 3
          }
        }
        float_val: 0.0
      }
    }
  }
}
node {
  name: "layer3/weights/Variable/Adadelta"
  op: "VariableV2"
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer3/weights/Variable"
      }
    }
  }
  attr {
    key: "container"
    value {
      s: ""
    }
  }
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "shape"
    value {
      shape {
        dim {
          size: 10
        }
        dim {
          size: 3
        }
      }
    }
  }
  attr {
    key: "shared_name"
    value {
      s: ""
    }
  }
}
node {
  name: "layer3/weights/Variable/Adadelta/Assign"
  op: "Assign"
  input: "layer3/weights/Variable/Adadelta"
  input: "zeros_8"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer3/weights/Variable"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: true
    }
  }
  attr {
    key: "validate_shape"
    value {
      b: true
    }
  }
}
node {
  name: "layer3/weights/Variable/Adadelta/read"
  op: "Identity"
  input: "layer3/weights/Variable/Adadelta"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer3/weights/Variable"
      }
    }
  }
}
node {
  name: "zeros_9"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
          dim {
            size: 10
          }
          dim {
            size: 3
          }
        }
        float_val: 0.0
      }
    }
  }
}
node {
  name: "layer3/weights/Variable/Adadelta_1"
  op: "VariableV2"
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer3/weights/Variable"
      }
    }
  }
  attr {
    key: "container"
    value {
      s: ""
    }
  }
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "shape"
    value {
      shape {
        dim {
          size: 10
        }
        dim {
          size: 3
        }
      }
    }
  }
  attr {
    key: "shared_name"
    value {
      s: ""
    }
  }
}
node {
  name: "layer3/weights/Variable/Adadelta_1/Assign"
  op: "Assign"
  input: "layer3/weights/Variable/Adadelta_1"
  input: "zeros_9"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer3/weights/Variable"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: true
    }
  }
  attr {
    key: "validate_shape"
    value {
      b: true
    }
  }
}
node {
  name: "layer3/weights/Variable/Adadelta_1/read"
  op: "Identity"
  input: "layer3/weights/Variable/Adadelta_1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer3/weights/Variable"
      }
    }
  }
}
node {
  name: "zeros_10"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
          dim {
            size: 3
          }
        }
        float_val: 0.0
      }
    }
  }
}
node {
  name: "layer3/biases/Variable/Adadelta"
  op: "VariableV2"
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer3/biases/Variable"
      }
    }
  }
  attr {
    key: "container"
    value {
      s: ""
    }
  }
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "shape"
    value {
      shape {
        dim {
          size: 3
        }
      }
    }
  }
  attr {
    key: "shared_name"
    value {
      s: ""
    }
  }
}
node {
  name: "layer3/biases/Variable/Adadelta/Assign"
  op: "Assign"
  input: "layer3/biases/Variable/Adadelta"
  input: "zeros_10"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer3/biases/Variable"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: true
    }
  }
  attr {
    key: "validate_shape"
    value {
      b: true
    }
  }
}
node {
  name: "layer3/biases/Variable/Adadelta/read"
  op: "Identity"
  input: "layer3/biases/Variable/Adadelta"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer3/biases/Variable"
      }
    }
  }
}
node {
  name: "zeros_11"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
          dim {
            size: 3
          }
        }
        float_val: 0.0
      }
    }
  }
}
node {
  name: "layer3/biases/Variable/Adadelta_1"
  op: "VariableV2"
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer3/biases/Variable"
      }
    }
  }
  attr {
    key: "container"
    value {
      s: ""
    }
  }
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "shape"
    value {
      shape {
        dim {
          size: 3
        }
      }
    }
  }
  attr {
    key: "shared_name"
    value {
      s: ""
    }
  }
}
node {
  name: "layer3/biases/Variable/Adadelta_1/Assign"
  op: "Assign"
  input: "layer3/biases/Variable/Adadelta_1"
  input: "zeros_11"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer3/biases/Variable"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: true
    }
  }
  attr {
    key: "validate_shape"
    value {
      b: true
    }
  }
}
node {
  name: "layer3/biases/Variable/Adadelta_1/read"
  op: "Identity"
  input: "layer3/biases/Variable/Adadelta_1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer3/biases/Variable"
      }
    }
  }
}
node {
  name: "Adadelta/lr"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
        }
        float_val: 0.10000000149
      }
    }
  }
}
node {
  name: "Adadelta/rho"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
        }
        float_val: 0.949999988079
      }
    }
  }
}
node {
  name: "Adadelta/epsilon"
  op: "Const"
  attr {
    key: "dtype"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_FLOAT
        tensor_shape {
        }
        float_val: 9.99999993923e-09
      }
    }
  }
}
node {
  name: "Adadelta/update_layer1/weights/Variable/ApplyAdadelta"
  op: "ApplyAdadelta"
  input: "layer1/weights/Variable"
  input: "layer1/weights/Variable/Adadelta"
  input: "layer1/weights/Variable/Adadelta_1"
  input: "Adadelta/lr"
  input: "Adadelta/rho"
  input: "Adadelta/epsilon"
  input: "gradients/layer1/Wx_plus_b/MatMul_grad/tuple/control_dependency_1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer1/weights/Variable"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: false
    }
  }
}
node {
  name: "Adadelta/update_layer1/biases/Variable/ApplyAdadelta"
  op: "ApplyAdadelta"
  input: "layer1/biases/Variable"
  input: "layer1/biases/Variable/Adadelta"
  input: "layer1/biases/Variable/Adadelta_1"
  input: "Adadelta/lr"
  input: "Adadelta/rho"
  input: "Adadelta/epsilon"
  input: "gradients/layer1/Wx_plus_b/add_grad/tuple/control_dependency_1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer1/biases/Variable"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: false
    }
  }
}
node {
  name: "Adadelta/update_layer2/weights/Variable/ApplyAdadelta"
  op: "ApplyAdadelta"
  input: "layer2/weights/Variable"
  input: "layer2/weights/Variable/Adadelta"
  input: "layer2/weights/Variable/Adadelta_1"
  input: "Adadelta/lr"
  input: "Adadelta/rho"
  input: "Adadelta/epsilon"
  input: "gradients/layer2/Wx_plus_b/MatMul_grad/tuple/control_dependency_1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer2/weights/Variable"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: false
    }
  }
}
node {
  name: "Adadelta/update_layer2/biases/Variable/ApplyAdadelta"
  op: "ApplyAdadelta"
  input: "layer2/biases/Variable"
  input: "layer2/biases/Variable/Adadelta"
  input: "layer2/biases/Variable/Adadelta_1"
  input: "Adadelta/lr"
  input: "Adadelta/rho"
  input: "Adadelta/epsilon"
  input: "gradients/layer2/Wx_plus_b/add_grad/tuple/control_dependency_1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer2/biases/Variable"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: false
    }
  }
}
node {
  name: "Adadelta/update_layer3/weights/Variable/ApplyAdadelta"
  op: "ApplyAdadelta"
  input: "layer3/weights/Variable"
  input: "layer3/weights/Variable/Adadelta"
  input: "layer3/weights/Variable/Adadelta_1"
  input: "Adadelta/lr"
  input: "Adadelta/rho"
  input: "Adadelta/epsilon"
  input: "gradients/layer3/Wx_plus_b/MatMul_grad/tuple/control_dependency_1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer3/weights/Variable"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: false
    }
  }
}
node {
  name: "Adadelta/update_layer3/biases/Variable/ApplyAdadelta"
  op: "ApplyAdadelta"
  input: "layer3/biases/Variable"
  input: "layer3/biases/Variable/Adadelta"
  input: "layer3/biases/Variable/Adadelta_1"
  input: "Adadelta/lr"
  input: "Adadelta/rho"
  input: "Adadelta/epsilon"
  input: "gradients/layer3/Wx_plus_b/add_grad/tuple/control_dependency_1"
  attr {
    key: "T"
    value {
      type: DT_FLOAT
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@layer3/biases/Variable"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: false
    }
  }
}
node {
  name: "Adadelta/update"
  op: "NoOp"
  input: "^Adadelta/update_layer1/weights/Variable/ApplyAdadelta"
  input: "^Adadelta/update_layer1/biases/Variable/ApplyAdadelta"
  input: "^Adadelta/update_layer2/weights/Variable/ApplyAdadelta"
  input: "^Adadelta/update_layer2/biases/Variable/ApplyAdadelta"
  input: "^Adadelta/update_layer3/weights/Variable/ApplyAdadelta"
  input: "^Adadelta/update_layer3/biases/Variable/ApplyAdadelta"
}
node {
  name: "Adadelta/value"
  op: "Const"
  input: "^Adadelta/update"
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@global_step"
      }
    }
  }
  attr {
    key: "dtype"
    value {
      type: DT_INT64
    }
  }
  attr {
    key: "value"
    value {
      tensor {
        dtype: DT_INT64
        tensor_shape {
        }
        int64_val: 1
      }
    }
  }
}
node {
  name: "Adadelta"
  op: "AssignAdd"
  input: "global_step"
  input: "Adadelta/value"
  attr {
    key: "T"
    value {
      type: DT_INT64
    }
  }
  attr {
    key: "_class"
    value {
      list {
        s: "loc:@global_step"
      }
    }
  }
  attr {
    key: "use_locking"
    value {
      b: false
    }
  }
}
node {
  name: "init"
  op: "NoOp"
  input: "^layer1/weights/Variable/Assign"
  input: "^layer1/biases/Variable/Assign"
  input: "^layer2/weights/Variable/Assign"
  input: "^layer2/biases/Variable/Assign"
  input: "^layer3/weights/Variable/Assign"
  input: "^layer3/biases/Variable/Assign"
  input: "^global_step/Assign"
  input: "^layer1/weights/Variable/Adadelta/Assign"
  input: "^layer1/weights/Variable/Adadelta_1/Assign"
  input: "^layer1/biases/Variable/Adadelta/Assign"
  input: "^layer1/biases/Variable/Adadelta_1/Assign"
  input: "^layer2/weights/Variable/Adadelta/Assign"
  input: "^layer2/weights/Variable/Adadelta_1/Assign"
  input: "^layer2/biases/Variable/Adadelta/Assign"
  input: "^layer2/biases/Variable/Adadelta_1/Assign"
  input: "^layer3/weights/Variable/Adadelta/Assign"
  input: "^layer3/weights/Variable/Adadelta_1/Assign"
  input: "^layer3/biases/Variable/Adadelta/Assign"
  input: "^layer3/biases/Variable/Adadelta_1/Assign"
}
versions {
  producer: 21
}
